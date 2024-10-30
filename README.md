# aws-account-bootstrapping

A collection of AWS Account bootstrapping automation as per https://woodmac.atlassian.net/wiki/spaces/WMTECH/pages/25862430/AWS+Account+Bootstrapping

As per the documentation above, the boostrapping contains the following areas. This repository will address bootstrapping certain aspects of those accounts via automation.

* Request the account (AWS)
* App Ops account access
* Disabling auto-remediation for certain config rules
* VPC per Environment
* Woodmac-specific Key Pairs
* Parameter Store
* DNS Management
* Live Services Deployment Bucket
* Custom Environment Mapping
* Governance
* Jenkins (CI/CD)
* Monitoring
* Logging
* Business stakeholder access

## DNS Management

Setup of hosted zones and certificates

### Hosted Zones Deployment

#### Create a stack and a change set and print the change without execution

```bash
AWS_REGION=us-east-1 AWS_ENVIRONMENT=<name_of_environment> make deploy_dns_hosted_zones
```

#### Create a stack, a change set, and execute it.

```bash
AWS_REGION=us-east-1 AWS_ENVIRONMENT=<name_of_environment> RUN_MODE=execute make deploy_dns_hosted_zones
```

#### Stack outputs and SSM Parameters

| SSM Parameter Name | Stack Output Name | Description |
| ----------- | ----------- | ----------- |
| /${Environment}/cloudops/dns/public_hosted_zone_id_${HostedZoneSubdomain} | PublicHostedZoneId | The Public Hosted Zone Id |
| /${Environment}/cloudops/dns/public_hosted_zone_ns_servers_${HostedZoneSubdomain} | PublicHostedZoneNSServers | A JSON object with the NS servers for the public hosted zone (for woodmac.com addition) |
| /${Environment}/cloudops/dns/private_hosted_zone_id_${HostedZoneSubdomain} | PrivateHostedZoneId | The Private Hosted Zone Id |
| /${Environment}/cloudops/dns/private_hosted_zone_ns_servers_${HostedZoneSubdomain} | PrivateHostedZoneNSServers | A JSON object with the NS servers for the private hosted zone (for DNS Resolver config) |

### ACM Certificates Deployment

This needs to be deployed after the Hosted Zones Deployment section has been completed

#### Create a stack and a change set and print the change without execution

```bash
AWS_REGION=us-east-1 AWS_ENVIRONMENT=<name_of_environment> make deploy_acm_certificates
AWS_REGION=eu-west-1 AWS_ENVIRONMENT=<name_of_environment> make deploy_acm_certificates
```

#### Create a stack, a change set, and execute it.

```bash
AWS_REGION=us-east-1 AWS_ENVIRONMENT=<name_of_environment> RUN_MODE=execute make deploy_acm_certificates
AWS_REGION=eu-west-1 AWS_ENVIRONMENT=<name_of_environment> RUN_MODE=execute make deploy_acm_certificates
```

#### Stack Outputs

| Parameter Name | Stack Output Name | Description |
| ----------- | ----------- | ----------- |
| /${Environment}/cloudops/acm/wildcard_certificate_arn_${CertificateSubdomain} | ACMCertificateArn | The ARN of the wildcard certificate for the subdomain |
|  | ACMCertificateDomainName | The domain name for which we have created a certificate |

## Networking bootstrapping actions

In some cases the networking setup between accounts will require further resources to be created in order to create VPC Endpoints or other connectivity between accounts.

### VPC Creation

It is recommended to always executed VPC changes as DRY RUN due to the probability of deleting resources if there is a mistake.

#### CIDR Math and Allocation

To start with, we are creating only /22 VPCs with 8 /25 subnets in them of equal size. In the future we might modify this but this is the standard "Type 1" VPC as per https://woodmac.atlassian.net/wiki/spaces/WMTECH/pages/25917751/AWS+VPC+Layouts.

To get the CIDR ranges for your VPC follow the steps:

1. Go to https://woodmac.atlassian.net/wiki/spaces/WMTECH/pages/25765442/AWS+Azure+Woodmac+Networking#AWS%2FAzure-Global-IP-addressing-%3A and confirm the CIDR range you should be working in based on the region in AWS.
2. Go to the Network account in VPC IP Address Manager and go to the /13 space you need to allocate a /22 in. Then go to a space within that range that is unoccupied and choose a range. Double check it's not present in https://woodmac.atlassian.net/wiki/spaces/WMTECH/pages/25757210/Network+Ranges.
3. Once the range is chosen, let's suppose it is 10.1.0.0/22. You can use the `sipcalc` linux cli tool to get the CIDR ranges of the /25 subnets. In to do that put `sipcalc -n 8 10.1.0.0/25` in the terminal. Please note it is a `/25` as we are asking for 8 subnets of size /25 start with 10.1.0.0. This will print something that looks like this. Use the first column of IPs and add a /25 at the end of each to populate the values of the environment variables in the next section:

    ```bash
    $ sipcalc -n 8 10.1.0.0/25
    -[ipv4 : 10.1.0.0/25] - 0

    [Networks]
    Network                 - 10.1.0.0        - 10.1.0.127 (current)
    Network                 - 10.1.0.128      - 10.1.0.255
    Network                 - 10.1.1.0        - 10.1.1.127
    Network                 - 10.1.1.128      - 10.1.1.255
    Network                 - 10.1.2.0        - 10.1.2.127
    Network                 - 10.1.2.128      - 10.1.2.255
    Network                 - 10.1.3.0        - 10.1.3.127
    Network                 - 10.1.3.128      - 10.1.3.255
    ```

4. The CIDR range will not appear immediately in VPC IPAM after the VPC is created but it will appear at some point, unknown exactly how long but upon checking the next day the ranges have been updated.

#### Create a stack and a change set and print the change without execution

Optionally set up CWAN attachment and routed.
Note: Deployment with CWAN attachment takes an extra 8-10 minutes. It is recommended to do it after VPC has been created.

```bash
export ATTACH_TO_CWAN=true
export CWAN_SEGMENT=nonprod
```

```bash
export AWS_ENVIRONMENT=<name_of_environment> \
> AWS_REGION=<aws_region> \
> AWS_ACCOUNT_ALIAS=<name-of-account-short> \
> VPC_CIDR=<vpc-cidr> \
> PUBLIC_WEB_SUBNET_01=<pub-web-sub-1-cidr> \
> PUBLIC_WEB_SUBNET_02=<pub-web-sub-2-cidr> \
> PRIVATE_WEB_SUBNET_01=<priv-web-sub-1-cidr> \
> PRIVATE_WEB_SUBNET_02=<priv-web-sub-2-cidr> \
> PRIVATE_APP_SUBNET_01=<priv-app-sub-1-cidr> \
> PRIVATE_APP_SUBNET_02=<priv-app-sub-2-cidr> \
> PRIVATE_DB_SUBNET_01=<priv-db-sub-1-cidr> \
> PRIVATE_DB_SUBNET_02=<priv-db-sub-2-cidr>
make deploy_vpc_type_1
```


#### Stack Outputs

| SSM Param | Stack Output Name | Description |
| ----------- | ----------- | ----------- |
| | CloudWANAttachmentID | The ID of the CloudWAN Attachment, 'no attachment' if not attached |
| /<env>/sre/dynamodb-endpoint | DynamoDBEndpointId | Id for DynamoDB VPC endpoint |
| /<env>/sre/rt-priv-1-id | PrivateRouteTableAZ01Id | Id for private route table az 01 |
| /<env>/sre/rt-priv-2-id | PrivateRouteTableAZ02Id | Id for private route table az 02 |
| /<env>/sre/s3-endpoint | S3EndpointId | Id for S3 VPC endpoint |
| /<env>/sre/vpc-id | VPCId | VPC Id |
| /<env>/sre/priv-1-app-subnet | PrivateSubnetAppAZ01Id | Private Subnet App 1 |
| /<env>/sre/priv-2-app-subnet | PrivateSubnetAppAZ02Id | Private Subnet App 2 |
| /<env>/sre/priv-1-db-subnet | PrivateSubnetDBAZ01Id | Private Subnet DB 1 |
| /<env>/sre/priv-2-db-subnet | PrivateSubnetDBAZ02Id | Private Subnet DB 2 |
| /<env>/sre/priv-1-web-subnet | PrivateSubnetWebAZ01Id | Private Subnet Web 1 |
| /<env>/sre/priv-2-web-subnet | PrivateSubnetWebAZ02Id | Private Subnet Web 2 |
| /<env>/sre/pub-1-web-subnet | PublicSubnetWebAZ01Id | Public Subnet Web 1 |
| /<env>/sre/pub-2-web-subnet | PublicSubnetWebAZ02Id | Public Subnet Web 2 |
| | NATGatewayEP01 | Elastic IP of NAT GW az 01 |
| | NATGatewayEP02 | Elastic IP of NAT GW az 02 |

### Common VPC Endpoints

A setup done for the LDP accounts but might be required in a very similar capacity for many accounts.
**TODO**
Will most probably need to be parameterised so it only creates all of the resources in certain cases.

#### Create a stack and a change set and print the change without execution

*Please note you need to have the Environment Mappings deployed before proceeding*

```bash
AWS_REGION=us-east-1 AWS_ENVIRONMENT=<name_of_environment> make deploy_common_vpc_endpoints
```

#### Create a stack, a change set, and execute it.

*Please note you need to have the Environment Mappings deployed before proceeding*

```bash
AWS_REGION=us-east-1 AWS_ENVIRONMENT=<name_of_environment> RUN_MODE=execute make deploy_common_vpc_endpoints
```

#### Stack Outputs

| SSM Param | Stack Output Name | Description |
| ----------- | ----------- | ----------- |
| | APIGatewayEndpointSGId | ID Of the API Gateway Endpoint Security Group |
| | ElasticCloudEndpointSGId | ID Of the Elastic Cloud Endpoint Security Group |
| | PrivateLinkNLBCanonicalZone | The CanonicalZoneId of the PrivateLink NLB |
| /<env>/wm-common-vpc-endpoints-private-link-nlb-arn | PrivateLinkNLBArn | The Arn of the PrivateLink NLB |
| | PrivateLinkNLBFullName | The Full Name of the PrivateLink NLB |
| | ElasticPrivateHostedZoneId | The Elastic Private Hosted Zone Id |

### AWS Service managed VPC Endpoints

A setup done for the LDP curation accounts but might be required in a very similar capacity for many accounts.

#### Create a stack and a change set and print the change without execution

*Please note you have to use elevated permissions in AWS for creating these resources*

```bash
AWS_REGION=us-east-1 AWS_ENVIRONMENT=<name_of_environment> AWS_SERVICE_NAME=<aws_service_name> PROJECT_CODE=<project_code> make deploy_awsservice_endpoints
```

#### Create a stack, a change set, and execute it.

*Please note you have to use elevated permissions in AWS for creating these resources*

```bash
AWS_REGION=us-east-1 AWS_ENVIRONMENT=<name_of_environment> AWS_SERVICE_NAME=<aws_service_name> PROJECT_CODE=<project_code> RUN_MODE=execute make deploy_awsservice_endpoints
```

#### Stack Outputs

| SSM Param | Stack Output Name | Description |
| ----------- | ----------- | ----------- |
| | RedshiftEndpoint{ClusterName}Address | The URL of each Service Endpoint  |
| /{Environment}/{ProductCode}/redshift-endpoint-url | RedshiftEndpoint${ClusterName}Address | The URL of each Service Endpoint |

### Privatelink NLB Modules

A setup done for the LDP accounts but might be required in a very similar capacity for many accounts.
Creates target group and listener for the NLB defined in the common-vpc-endpoints deployment.
They are dependent on the SSM parameter `wm-common-vpc-endpoints-private-link-nlbs` and the parameter that holds the ARN of the NLB `/<env>/wm-common-vpc-endpoints-private-link-nlb-arn`.

#### Create a stack and a change set and print the change without execution

*Please note you need to have the Environment Mappings deployed before proceeding*

```bash
AWS_REGION=us-east-1 AWS_ENVIRONMENT=<name_of_environment> make deploy_privatelink_nlb_modules
```

#### Create a stack, a change set, and execute it.

*Please note you need to have the Environment Mappings deployed before proceeding*

```bash
AWS_REGION=us-east-1 AWS_ENVIRONMENT=<name_of_environment> RUN_MODE=execute make deploy_privatelink_nlb_modules
```

### WMProd Private Link

A setup done for the LDP accounts but might be required in a very similar capacity for many accounts. Applicable only for dev, int, uat, prod environments.

#### Create a stack and a change set and print the change without execution

*Please note you need to have the Environment Mappings deployed before proceeding*

```bash
AWS_REGION=us-east-1 AWS_ENVIRONMENT=<name_of_environment> make deploy_wm_privatelink_security
```

#### Create a stack, a change set, and execute it.

*Please note you need to have the Environment Mappings deployed before proceeding*

```bash
AWS_REGION=us-east-1 AWS_ENVIRONMENT=<name_of_environment> RUN_MODE=execute make deploy_wm_privatelink_security
```

#### Stack Outputs

| Stack Output Name | Description |
| ----------- | ----------- |
| LDPPrivateLinkSGSGId | ID Of the LDP Private Link Security Group |

## Various small bootstrapping actions

### Nexus Parameters

#### Create a stack and a change set and print the change without execution

```bash
AWS_REGION=us-east-1 AWS_ENVIRONMENT=<name_of_environment> make deploy_nexus_parameters
AWS_REGION=eu-west-1 AWS_ENVIRONMENT=<name_of_environment> make deploy_nexus_parameters
```

#### Create a stack, a change set, and execute it.

```bash
AWS_REGION=us-east-1 AWS_ENVIRONMENT=<name_of_environment> RUN_MODE=execute make deploy_nexus_parameters
AWS_REGION=eu-west-1 AWS_ENVIRONMENT=<name_of_environment> RUN_MODE=execute make deploy_nexus_parameters
```

### Liveservices Deployment Bucket

#### Create a stack and a change set and print the change without execution

```bash
AWS_REGION=us-east-1 AWS_ENVIRONMENT=<name_of_environment> AWS_ACCOUNT_NAME=<name_of_aws_account_minus_woodmac> make deploy_liveservices_deploy_bucket
AWS_REGION=eu-west-1 AWS_ENVIRONMENT=<name_of_environment> AWS_ACCOUNT_NAME=<name_of_aws_account_minus_woodmac> make deploy_liveservices_deploy_bucket
```

#### Create a stack, a change set, and execute it.

```bash
AWS_REGION=us-east-1 AWS_ENVIRONMENT=<name_of_environment> AWS_ACCOUNT_NAME=<name_of_aws_account_minus_woodmac> RUN_MODE=execute make deploy_liveservices_deploy_bucket
AWS_REGION=eu-west-1 AWS_ENVIRONMENT=<name_of_environment> AWS_ACCOUNT_NAME=<name_of_aws_account_minus_woodmac> RUN_MODE=execute make deploy_liveservices_deploy_bucket
```

#### Stack Outputs

| Parameter Name | Stack Output Name | Description |
| ----------- | ----------- | ----------- |
| /liveservices/deployment-bucket-name | WoodmacLiveServicesDeployBucketName | The name of the Liveservices delpoyment bucket in the account and region |

### Liveservices Key Pair

#### Create a stack and a change set and print the change without execution

*Please note you will need aws cli >= 1.23.7 and cfn-lint >= 0.59.1*

Get the liveservices-key-pair.pub from https://vault.core.woodmac.com/ui/vault/secrets/secrets/show/live-services/livesergvices-key-pair.

```bash
AWS_REGION=us-east-1 AWS_ENVIRONMENT=<name_of_environment> PUBLIC_KEY_MATERIAL="<put_public_key_from_vault>" make deploy_liveservices_key_pair
AWS_REGION=eu-west-1 AWS_ENVIRONMENT=<name_of_environment> PUBLIC_KEY_MATERIAL="<put_public_key_from_vault>" make deploy_liveservices_key_pair
```

Compare outputs with fingerprint from vault https://vault.core.woodmac.com/ui/vault/secrets/secrets/show/live-services/livesergvices-key-pair

#### Create a stack, a change set, and execute it.

*Please note you will need aws cli >= 1.23.7 and cfn-lint >= 0.59.1*

Get the liveservices-key-pair.pub from https://vault.core.woodmac.com/ui/vault/secrets/secrets/show/live-services/livesergvices-key-pair.

```bash
AWS_REGION=us-east-1 AWS_ENVIRONMENT=<name_of_environment> PUBLIC_KEY_MATERIAL="<put_public_key_from_vault>" RUN_MODE=execute make deploy_liveservices_key_pair
AWS_REGION=eu-west-1 AWS_ENVIRONMENT=<name_of_environment> PUBLIC_KEY_MATERIAL="<put_public_key_from_vault>" RUN_MODE=execute make deploy_liveservices_key_pair
```

Compare outputs with fingerprint from vault https://vault.core.woodmac.com/ui/vault/secrets/secrets/show/live-services/livesergvices-key-pair

#### Stack Outputs

| Stack Output Name | Description |
| ----------- | ----------- |
| KeyPairId | The ID of the Live Services Key pair |
| KeyFingerprint | The fingerprint of the Live Services Key pair |

### CloudWatch Logs Resource Policy

Some accounts need a consolidation for the cloudwatch logs resource policy due to limits that
are region wide. Please deploy only once per account per region.
[AWS Logs and resource policy](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/AWS-logs-and-resource-policy.html)
[AWS Logs resource policy limits](https://docs.aws.amazon.com/step-functions/latest/dg/bp-cwl.html)

For checking the resource policy for the region please use:
`aws logs --region us-east-1 describe-resource-policies`

#### create a stack and a change set and print the change without execution

```bash
AWS_REGION=us-east-1 AWS_ENVIRONMENT=<name_of_environment> AWS_ACCOUNT_NAME=<name_of_aws_account_minus_woodmac> make deploy_cw_logs_resource_policy
AWS_REGION=eu-west-1 AWS_ENVIRONMENT=<name_of_environment> AWS_ACCOUNT_NAME=<name_of_aws_account_minus_woodmac> make deploy_cw_logs_resource_policy
```

#### Create a stack, a change set, and execute it.

```bash
AWS_REGION=us-east-1 AWS_ENVIRONMENT=<name_of_environment> AWS_ACCOUNT_NAME=<name_of_aws_account_minus_woodmac> RUN_MODE=execute make deploy_cw_logs_resource_policy
AWS_REGION=eu-west-1 AWS_ENVIRONMENT=<name_of_environment> AWS_ACCOUNT_NAME=<name_of_aws_account_minus_woodmac> RUN_MODE=execute make deploy_cw_logs_resource_policy
```

### Privatelink setup

In order to setup PrivateLink between environments or with other environments two things need to be considered: provider and consumer setup.

#### Provider

The folder structure is the following:

```
.
├── Makefile
├── README.md
└── networking
    └── privatelink
        └── producers
            └── producer_env_name
                └── privatelink-producer.yml
```

For every producer environment, please add one folder with the name of the producer (usually the account/environment name). Some environments might have multiple endpoint services in them. In those cases please add them each as another environment.

#### create a stack and a change set and print the change without execution

```bash
AWS_REGION=<aws_region> AWS_ENVIRONMENT=<name_of_environment> PRIVATELINK_CONNECTION_NAME=<environment_or_account_name> make deploy_privatelink_producer
```

#### Create a stack, a change set, and execute it.

```bash
AWS_REGION=<aws_region> AWS_ENVIRONMENT=<name_of_environment> PRIVATELINK_CONNECTION_NAME=<environment_or_account_name> RUN_MODE=execute make deploy_privatelink_producer
```

#### Consumer

```
.
├── Makefile
├── README.md
└── networking
    └── privatelink
        └── consumers
            └── consumer_env_name-producer_env_name
                └── privatelink-consumer.yml
```

For every consumer-producer environment, please add one folder with the name of the consumer-producer (usually the account/environment name on either side). It is unlikely there are multiple connections between the same environments but if that is the case (ie more than one producer in that env), please add another folder.

#### create a stack and a change set and print the change without execution

```bash
AWS_REGION=<aws_region> AWS_ENVIRONMENT=<name_of_environment> PRIVATELINK_CONNECTION_NAME=<consumer_environment_or_account_name>-<producer_environment_or_account_name> make deploy_privatelink_consumer
```

#### Create a stack, a change set, and execute it.

```bash
AWS_REGION=<aws_region> AWS_ENVIRONMENT=<name_of_environment> PRIVATELINK_CONNECTION_NAME=<consumer_environment_or_account_name>-<producer_environment_or_account_name> RUN_MODE=execute make deploy_privatelink_consumer
```
