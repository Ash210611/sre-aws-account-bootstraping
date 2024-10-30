# Helper Tools

## nlb-processing

A simple click application that gets encoded values from a secret and transforms them so they can be placed in an encoded SSM parameter for AWS CloudFormation consumption.
This is necessary because CF cannot do any dictionary manipulation and this is the only way to keep the code DRY

### Secret encoding

The secret data format is the following
```json
{
  "external_environment_name": {
	"port": "80",
	"nlb_ips" [
		"1.2.3.4",
		"5.6.7.8"
	]
  },
  "external_environment_name2": {
	"port": "81",
	"nlb_ips" [
		"10.20.30.40",
		"50.60.70.80"
	]
  }
}
```

The IPs need to be in the same VPC as the NLB or otherwise reachable, otherwise a Target group cannot be created.

### SSM parameter encoding

In order to put everything in a single SSM parameter, there are 3 levels of lists that are encoded with different separators:

* The highest level list (with each item being the full information for each load balancer) contains the information required for each target group and listener combination. It uses `,` comma as a separator.
* The next level list includes 3 elements `[modulename, port, nlb_ips]` and is separated by `;` semicolon.
* The last level list includes 2 or more IPs for each NLB and is separated by `&`.

A fully encoded string looks like
`ldpmodule1;80;1.2.3.4&5.6.7.8,ldpmodule2;81;10.20.30.40&50.60.70.80`
It is saved as a StringList within SSM for easier ingestion within CF. CF can then do splits on the various levels in order to define lists of items.

## Populating SSM parameter from secret

There is a small Click CLI app written in Python that does the json to string converstion with the encoding described above

### Run the app

```bash
pipenv install
pipenv run python -m nlb-processing --help
Usage: python -m nlb-processing [OPTIONS]

Options:
  -s, --secret-prefix TEXT        The prefix for creation of the secret name
  -so, --secret-name-override TEXT
                                  The name of the secret to override env and
                                  prefix details
  -e, --environment TEXT          The AWS Environment in which you are
                                  deploying  [required]
  -r, --region TEXT               The AWS region in which you are deploying
  -l, --logging-level TEXT        Logger level
  -p, --ssm-parameter-name TEXT   An override for the ssm parameter name
  -d, --dry-run                   Run in dry mode without writing to SSM
  --help                          Show this message and exit.pipenv run
```

### Set up ssm parameter

The secret called `wm-common-vpc-endpoints-private-link-<env>` needs to be created with at least one key-value pair as per the scheme above.

```bash
# assume correct AWS credentials and set env variables accordingly
pipenv run pythom -m nlb-processing -e <env>
```
