"""
Module that contains the command line app.
Why does this file exist, and why not put this in __main__?
  You might be tempted to import things from __main__ later, but that will cause
  problems: the code will get executed twice:
  - When you run `python -m mappings_automation` python will execute
    ``__main__.py`` as a script. That means there won't be any
    ``nameless.__main__`` in ``sys.modules``.
  - When you import __main__ it will get executed again (as a module) because
    there's no ``mappings_automation.__main__`` in ``sys.modules``.
  Also see (1) from http://click.pocoo.org/5/setuptools/#setuptools-integration
"""
import click
from typing import Dict
import json
import boto3
from .setup_logging import get_logger


APP_NAME = "nlb_processing"
COMPONENT_NAME = "nlb_processing"
FINAL_SSM_PARAMETER_VALUE = []

# ---------- Logger Setup ----------
logger = get_logger(__name__)
# Global variables are reused across execution contexts (if available)
session = boto3.Session()

@click.command()
@click.option('-s', '--secret-prefix', help='The prefix for creation of the secret name', default='wm-common-vpc-endpoints-private-link')
@click.option('-so', '--secret-name-override', help='The name of the secret to override env and prefix details')
@click.option('-e', '--environment', required=True, help='The AWS Environment in which you are deploying')
@click.option('-r', '--region', default='us-east-1', help='The AWS region in which you are deploying')
@click.option('-l', '--logging-level', default='INFO', help='Logger level')
@click.option('-p', '--ssm-parameter-name', default='wm-common-vpc-endpoints-private-link-nlbs', help='An override for the ssm parameter name')
@click.option('-d', '--dry-run', is_flag=True, default=False, show_default=True, help='Run in dry mode without writing to SSM')
def cli(environment: str,
        secret_prefix: str,
        secret_name_override: str,
        region: str,
        logging_level: str,
        ssm_parameter_name: str,
        dry_run: bool,
) -> int:
    logger = get_logger(__name__, logging_level)
    secretsmanager_client = session.client('secretsmanager',region_name=region)
    ssm_client = session.client('ssm',region_name=region)
    logger.info(f"Configuring in environment: {environment}")
    secret_name = secret_name_override if secret_name_override else f'{secret_prefix}-{environment}'
    logger.info(f"Secret name is: {secret_name}")
    sm_response = secretsmanager_client.get_secret_value(
      SecretId=secret_name,
    )
    logger.debug(sm_response)
    secret_value = json.loads(sm_response.get('SecretString'))
    logger.debug(f"The secret value is: {secret_value}")
    secret_keys = list(secret_value.keys())
    logger.info(f"Will process config for the following load balancers: {secret_keys}")
    process_secret_keys(secret_value)
    logger.info(f"This is the final String: '{','.join(FINAL_SSM_PARAMETER_VALUE)}'")
    if dry_run:
      logger.info('Dry run has been selected, skipping writing to SSM parameter')
    else:
      ssm_response = ssm_client.put_parameter(
        Name=ssm_parameter_name,
        Description='A parameter holding the NLBs to configure as target groups and listeners for the PrivateLink NLB',
        Value=','.join(FINAL_SSM_PARAMETER_VALUE),
        Type='StringList',
        Overwrite=True,
      )
    return 0

def format_list_of_ips(element: list) -> str:
  return '&'.join(element)

def format_single_nlb_values(key: str, nlb_port: str, nlb_ips: str) -> str:
  return ';'.join([key, nlb_port, nlb_ips])

def format_single_nlb_list_item(key: str, element: Dict) -> None:
  nlb_port = str(element.get('port'))
  nlb_ips = format_list_of_ips(element.get('nlb_ips'))
  FINAL_SSM_PARAMETER_VALUE.append(format_single_nlb_values(key, nlb_port, nlb_ips))

def process_secret_keys(secret_value: Dict) -> None:
  for key, value in secret_value.items():
    nlb_list_item = json.loads(value)
    logger.debug(f"NLB list item: {nlb_list_item}")
    format_single_nlb_list_item(key,nlb_list_item)
