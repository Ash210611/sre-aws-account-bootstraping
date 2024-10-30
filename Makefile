.PHONY: lint deploy_dns_hosted_zones dns_hosted_zones

AWS_REGION ?= us-east-1

AWS_ENVIRONMENT ?= dev
# please use the name that has been given to the account at time of creation minus woodmac
# eg AWS account woodmacldpintegrationnonprod => AWS_ACCOUNT_NAME=ldpintegrationnonprod
AWS_ACCOUNT_NAME ?=

BUSINESS_UNIT ?= Woodmac
CONTACT ?= WM-SRE-Team@woodmac.com
PROJECT_CODE ?= OP-SRE
PRODUCT_CODE ?= AWS Governance
# The name of the thirdparty Endpoint Service we are integrating with
PRIVATELINK_ENDPOINT_SERVICE_NAME ?=


# Setting the short region for VPC use
ifeq ($(AWS_REGION), us-east-1)
	AWS_REGION_SHORT ?= use1
endif
ifeq ($(AWS_REGION), eu-west-1)
	AWS_REGION_SHORT ?= euw1
endif
ifeq ($(AWS_REGION), eu-central-1)
	AWS_REGION_SHORT ?= euc1
endif
ifeq ($(AWS_REGION), ap-southeast-1)
	AWS_REGION_SHORT ?= apse1
endif
ifeq ($(AWS_REGION), ap-southeast-2)
	AWS_REGION_SHORT ?= apse2
endif

HOSTED_ZONES_STACK_NAME ?= wm-hosted-zones-$(AWS_ENVIRONMENT)
HOSTED_ZONES_TEMPLATE_NAME ?= dns/hosted-zones.yml
ACM_CERTIFICATES_STACK_NAME ?= wm-acm-certificates-$(AWS_ENVIRONMENT)
ACM_CERTIFICATES_TEMPLATE_NAME ?= acm/certificates.yml
NEXUS_PARAMETERS_STACK_NAME ?= wm-nexus-parameters-$(AWS_ENVIRONMENT)
NEXUS_PARAMETERS_TEMPLATE_NAME ?= etc/nexus-parameters.yml
LIVESERVICES_DEPLOY_BUCKET_STACK_NAME ?= wm-liveservices-deploy-bucket-$(AWS_ENVIRONMENT)
LIVESERVICES_DEPLOY_BUCKET_TEMPLATE_NAME ?= etc/liveservices-deploy-bucket.yml
LIVESERVICES_KEY_PAIR_STACK_NAME ?= wm-liveservices-key-pair-$(AWS_ENVIRONMENT)
LIVESERVICES_KEY_PAIR_TEMPLATE_NAME ?= etc/liveservices-key-pair.yml
COMMON_VPC_ENDPOINTS_STACK_NAME ?= wm-common-vpc-endpoints-$(AWS_ENVIRONMENT)
COMMON_VPC_ENDPOINTS_TEMPLATE_NAME ?= networking/common-vpc-endpoints.yml
PRIVATELINK_NLB_MODULES_STACK_NAME ?= wm-privatelink-nlb-modules-$(AWS_ENVIRONMENT)
PRIVATELINK_NLB_MODULES_TEMPLATE_NAME ?= networking/privatelink-nlb-modules.yml
WM_PRIVATE_LINK_SECURITY_STACK_NAME ?= wm-private-link-security-$(AWS_ENVIRONMENT)
WM_PRIVATE_LINK_SECURITY_TEMPLATE_NAME ?= networking/01_privatelink_security.yml
CW_LOGS_RESOURCE_POLICY_STACK_NAME ?= wm-landing-zones-cloudwatch-logs-resource-policy
CW_LOGS_RESOURCE_POLICY_TEMPLATE_NAME ?= etc/cloudwatch-logs-resource-policy.yml
PRIVATELINK_CONSUMER_STACK_NAME ?= wm-privatelink-${PRIVATELINK_CONNECTION_NAME}-consumer-${AWS_ENVIRONMENT}
PRIVATELINK_CONSUMER_TEMPLATE_NAME ?= networking/privatelink/consumers/${PRIVATELINK_CONNECTION_NAME}/privatelink-consumer.yml
PRIVATELINK_PRODUCER_STACK_NAME ?= wm-privatelink-${PRIVATELINK_CONNECTION_NAME}-producer-${AWS_ENVIRONMENT}
PRIVATELINK_PRODUCER_TEMPLATE_NAME ?= networking/privatelink/producers/${PRIVATELINK_CONNECTION_NAME}/privatelink-producer.yml
VPC_ENDPOINTS_STACK_NAME ?= wm-vpc-endpoints-${ENDPOINTS_CONNECTION_NAME}-${AWS_ENVIRONMENT}
VPC_ENDPOINTS_TEMPLATE_NAME ?= networking/endpoints/${ENDPOINTS_CONNECTION_NAME}-interface-endpoints.yml
AWSSERVICE_ENDPOINTS_STACK_NAME ?= wm-${AWS_SERVICE_NAME}-endpoints-${AWS_ENVIRONMENT}
AWSSERVICE_ENDPOINTS_TEMPLATE_NAME ?= networking/endpoints/${AWS_ENVIRONMENT}/${AWS_SERVICE_NAME}-managed-endpoints.yml
VPC_TYPE_1_STACK_NAME ?= vpc-$(AWS_REGION_SHORT)-$(AWS_ACCOUNT_ALIAS)-$(AWS_ENVIRONMENT)
VPC_TYPE_1_TEMPLATE_NAME ?= networking/vpc/vpc_type_1.yml
# The regions and VPCs of the zScaler VPCs in the Network account that need to be authorized to resolve the private DNS
# vpc-prod-zscaler-use1-front-01
# vpc-prod-zscaler-euw1-front-01
# vpc-prod-zscaler-euc1-front-01
# vpc-prod-zscaler-apse1-front-01
# vpc-prod-zscaler-apse2-front-01
PRIVATELINK_AUTHORIZATION_VPC_PAIRS = \
	"us-east-1,vpc-0540658c6f1a0f938" \
	"eu-west-1,vpc-0ba4ecf05dae242e4" \
	"eu-central-1,vpc-0b7c326f4d4a102d1" \
	"ap-southeast-1,vpc-0453b284dcb3e8eeb" \
	"ap-southeast-2,vpc-024108730214e85dd"
# CWAN Config
ATTACH_TO_CWAN ?= false
#    AllowedValues:
#         - ghost
#         - transit
#         - management
#         - managementnonprod
#         - prod
#         - nonprod
#         - prodrestricted
CWAN_SEGMENT ?= ghost

RUN_MODE ?= dry

DEPLOY_COMMAND := aws cloudformation deploy --no-execute-changeset
DRYRUN_TARGETS_HOSTED_ZONES := change_set_$(HOSTED_ZONES_STACK_NAME)
DRYRUN_TARGETS_ACM_CERTIFICATES := change_set_$(ACM_CERTIFICATES_STACK_NAME)
DRYRUN_TARGETS_NEXUS_PARAMS := change_set_$(NEXUS_PARAMS_STACK_NAME)
DRYRUN_TARGETS_LIVESERVICES_DEPLOY_BUCKET := change_set_$(LIVESERVICES_DEPLOY_BUCKET_STACK_NAME)
DRYRUN_TARGETS_LIVESERVICES_KEY_PAIR := change_set_$(LIVESERVICES_KEY_PAIR_STACK_NAME)
DRYRUN_TARGETS_COMMON_VPC_ENDPOINTS := change_set_$(COMMON_VPC_ENDPOINTS_STACK_NAME)
DRYRUN_TARGETS_PRIVATELINK_NLB_MODULES := change_set_$(PRIVATELINK_NLB_MODULES_STACK_NAME)
DRYRUN_TARGETS_WM_PRIVATE_LINK_SECURITY := change_set_$(WM_PRIVATE_LINK_SECURITY_STACK_NAME)
DRYRUN_TARGETS_CW_LOGS_RESOURCE_POLICY := change_set_$(CW_LOGS_RESOURCE_POLICY_STACK_NAME)
DRYRUN_TARGETS_PRIVATELINK_CONSUMER := change_set_$(PRIVATELINK_CONSUMER_STACK_NAME)
DRYRUN_PRIVATELINK_CONSUMER_CRETE_TAGS := --dry-run
DRYRUN_PRIVATELINK_PRODUCER_CRETE_TAGS := --dry-run
DRYRUN_TARGETS_PRIVATELINK_PRODUCER := change_set_$(PRIVATELINK_PRODUCER_STACK_NAME)
DRYRUN_TARGETS_VPC_ENDPOINTS:= change_set_$(VPC_ENDPOINTS_STACK_NAME)
DRYRUN_TARGETS_AWSSERVICE_ENDPOINTS:= change_set_$(AWSSERVICE_ENDPOINTS_STACK_NAME)
DRYRUN_TARGETS_VPC_TYPE_1:= change_set_$(VPC_TYPE_1_STACK_NAME)

ifeq ($(RUN_MODE), execute)
	DEPLOY_COMMAND := aws cloudformation deploy
	DRYRUN_TARGETS_HOSTED_ZONES :=
	DRYRUN_TARGETS_ACM_CERTIFICATES :=
	DRYRUN_TARGETS_NEXUS_PARAMS :=
	DRYRUN_TARGETS_LIVESERVICES_DEPLOY_BUCKET :=
	DRYRUN_TARGETS_LIVESERVICES_KEY_PAIR :=
	DRYRUN_TARGETS_COMMON_VPC_ENDPOINTS :=
	DRYRUN_TARGETS_PRIVATELINK_NLB_MODULES :=
	DRYRUN_TARGETS_WM_PRIVATE_LINK_SECURITY :=
	DRYRUN_TARGETS_CW_LOGS_RESOURCE_POLICY :=
	DRYRUN_TARGETS_PRIVATELINK_CONSUMER :=
	DRYRUN_PRIVATELINK_CONSUMER_CRETE_TAGS :=
	DRYRUN_TARGETS_PRIVATELINK_PRODUCER :=
	DRYRUN_PRIVATELINK_PRODUCER_CRETE_TAGS :=
	DRYRUN_TARGETS_VPC_ENDPOINTS:=
	DRYRUN_TARGETS_AWSSERVICE_ENDPOINTS:=
	DRYRUN_TARGETS_VPC_TYPE_1:=
endif

# Condition for the naming convention of the stack as this one changed after the first env have been setup
# And changing the name of existing stack is quite painful and high effort
ifeq ($(AWS_ENVIRONMENT), prod)
	WM_PRIVATE_LINK_SECURITY_STACK_NAME = wm-prod-private-link-$(AWS_ENVIRONMENT)
endif

ifeq ($(AWS_ENVIRONMENT), uat)
	WM_PRIVATE_LINK_SECURITY_STACK_NAME = wm-prod-private-link-$(AWS_ENVIRONMENT)
endif

lint:  ## Lint all CF templates - requires cfn-lint to be installed (pip install cfn-lint)
	@cfn-lint **/*.yml \
		--regions us-east-1 eu-west-1 \
		--info

deploy_dns_hosted_zones: dns_hosted_zones $(DRYRUN_TARGETS_HOSTED_ZONES) print_stack_outputs-$(HOSTED_ZONES_STACK_NAME)

dns_hosted_zones:  ## Deploy DNS Hosted Zones CF stack to an AWS_ENVIRONMENT of your choice
	@$(DEPLOY_COMMAND) \
		--region $(AWS_REGION) \
		--template-file $(HOSTED_ZONES_TEMPLATE_NAME) \
		--stack-name $(HOSTED_ZONES_STACK_NAME) \
		--no-fail-on-empty-changeset \
		--parameter-overrides \
			"Environment=$(AWS_ENVIRONMENT)" \
			"HostedZoneSubdomain=$(AWS_ENVIRONMENT)" \
		--tags \
			"Contact=$(CONTACT)" \
			"Environment=$(AWS_ENVIRONMENT)" \
			"Name=$(HOSTED_ZONES_STACK_NAME)" \
			"BusinessUnit=$(BUSINESS_UNIT)" \
			"ProjectCode=$(PROJECT_CODE)" \
			"ProductCode=$(PRODUCT_CODE)"
	@aws cloudformation update-termination-protection \
		--region $(AWS_REGION) \
		--stack-name $(HOSTED_ZONES_STACK_NAME) \
		--enable-termination-protection


deploy_acm_certificates: acm_certificates $(DRYRUN_TARGETS_ACM_CERTIFICATES)

acm_certificates:  ## Deploy ACM Certificates CF stack to an AWS_ENVIRONMENT of your choice
	@$(DEPLOY_COMMAND) \
		--region $(AWS_REGION) \
		--template-file $(ACM_CERTIFICATES_TEMPLATE_NAME) \
		--stack-name $(ACM_CERTIFICATES_STACK_NAME) \
		--no-fail-on-empty-changeset \
		--parameter-overrides \
			"CertificateSubdomain=$(AWS_ENVIRONMENT)" \
			"Environment=$(AWS_ENVIRONMENT)" \
			"HostedZoneIdSSM=/$(AWS_ENVIRONMENT)/cloudops/dns/public_hosted_zone_id_$(AWS_ENVIRONMENT)" \
		--tags \
			"Contact=$(CONTACT)" \
			"Environment=$(AWS_ENVIRONMENT)" \
			"Name=$(ACM_CERTIFICATES_STACK_NAME)" \
			"BusinessUnit=$(BUSINESS_UNIT)" \
			"ProjectCode=$(PROJECT_CODE)" \
			"ProductCode=$(PRODUCT_CODE)"

	@aws cloudformation update-termination-protection \
		--region $(AWS_REGION) \
		--stack-name $(ACM_CERTIFICATES_STACK_NAME) \
		--enable-termination-protection

deploy_nexus_parameters: nexus_parameters $(DRYRUN_TARGETS_NEXUS_PARAMS)

nexus_parameters:  ## Deploy Nexus parameters CF stack to an AWS_ENVIRONMENT of your choice
	@$(DEPLOY_COMMAND) \
		--region $(AWS_REGION) \
		--template-file $(NEXUS_PARAMETERS_TEMPLATE_NAME) \
		--stack-name $(NEXUS_PARAMETERS_STACK_NAME) \
		--no-fail-on-empty-changeset \
		--tags \
			"Contact=$(CONTACT)" \
			"Environment=$(AWS_ENVIRONMENT)" \
			"Name=$(NEXUS_PARAMETERS_STACK_NAME)" \
			"BusinessUnit=$(BUSINESS_UNIT)" \
			"ProjectCode=$(PROJECT_CODE)"

	@aws cloudformation update-termination-protection \
		--region $(AWS_REGION) \
		--stack-name $(NEXUS_PARAMETERS_STACK_NAME) \
		--enable-termination-protection

deploy_liveservices_deploy_bucket: liveservices_deploy_bucket $(DRYRUN_TARGETS_LIVESERVICES_DEPLOY_BUCKET)

liveservices_deploy_bucket:  ## Deploy Liveservices Deployment Bucket CF stack to an AWS_ENVIRONMENT of your choice
	@$(DEPLOY_COMMAND) \
		--region $(AWS_REGION) \
		--template-file $(LIVESERVICES_DEPLOY_BUCKET_TEMPLATE_NAME) \
		--stack-name $(LIVESERVICES_DEPLOY_BUCKET_STACK_NAME) \
		--no-fail-on-empty-changeset \
		--parameter-overrides \
			"AWSAccountName=$(AWS_ACCOUNT_NAME)" \
		--tags \
			"Contact=$(CONTACT)" \
			"Environment=$(AWS_ENVIRONMENT)" \
			"Name=$(LIVESERVICES_DEPLOY_BUCKET_STACK_NAME)" \
			"BusinessUnit=$(BUSINESS_UNIT)" \
			"ProjectCode=$(PROJECT_CODE)"

	@aws cloudformation update-termination-protection \
		--region $(AWS_REGION) \
		--stack-name $(LIVESERVICES_DEPLOY_BUCKET_STACK_NAME) \
		--enable-termination-protection

deploy_liveservices_key_pair: liveservices_key_pair $(DRYRUN_TARGETS_LIVESERVICES_KEY_PAIR) print_stack_outputs_$(LIVESERVICES_KEY_PAIR_STACK_NAME)

liveservices_key_pair:  ## Deploy Liveservices Key Pair CF stack to an AWS_ENVIRONMENT of your choice
	@$(DEPLOY_COMMAND) \
		--region $(AWS_REGION) \
		--template-file $(LIVESERVICES_KEY_PAIR_TEMPLATE_NAME) \
		--stack-name $(LIVESERVICES_KEY_PAIR_STACK_NAME) \
		--no-fail-on-empty-changeset \
		--parameter-overrides \
			"PublicKeyMaterial=$(PUBLIC_KEY_MATERIAL)" \
		--tags \
			"Contact=$(CONTACT)" \
			"Environment=$(AWS_ENVIRONMENT)" \
			"Name=$(LIVESERVICES_KEY_PAIR_STACK_NAME)" \
			"BusinessUnit=$(BUSINESS_UNIT)" \
			"ProjectCode=$(PROJECT_CODE)"

	@aws cloudformation update-termination-protection \
		--region $(AWS_REGION) \
		--stack-name $(LIVESERVICES_KEY_PAIR_STACK_NAME) \
		--enable-termination-protection

deploy_common_vpc_endpoints: common_vpc_endpoints $(DRYRUN_TARGETS_COMMON_VPC_ENDPOINTS) print_stack_outputs_$(COMMON_VPC_ENDPOINTS_STACK_NAME)

common_vpc_endpoints:  ## Deploy Common VPC Endpoints CF stack to an AWS_ENVIRONMENT of your choice
	@$(DEPLOY_COMMAND) \
		--region $(AWS_REGION) \
		--template-file $(COMMON_VPC_ENDPOINTS_TEMPLATE_NAME) \
		--stack-name $(COMMON_VPC_ENDPOINTS_STACK_NAME) \
		--no-fail-on-empty-changeset \
		--parameter-overrides \
			"Environment=$(AWS_ENVIRONMENT)" \
		--tags \
			"Contact=$(CONTACT)" \
			"Environment=$(AWS_ENVIRONMENT)" \
			"Name=$(COMMON_VPC_ENDPOINTS_STACK_NAME)" \
			"BusinessUnit=$(BUSINESS_UNIT)" \
			"ProjectCode=$(PROJECT_CODE)"

	@aws cloudformation update-termination-protection \
		--region $(AWS_REGION) \
		--stack-name $(COMMON_VPC_ENDPOINTS_STACK_NAME) \
		--enable-termination-protection

deploy_privatelink_nlb_modules: privatelink_nlb_modules $(DRYRUN_TARGETS_PRIVATELINK_NLB_MODULES)

privatelink_nlb_modules:  ## Deploy Privatelink NLB Modules CF stack to an AWS_ENVIRONMENT of your choice
	@$(DEPLOY_COMMAND) \
		--region $(AWS_REGION) \
		--template-file $(PRIVATELINK_NLB_MODULES_TEMPLATE_NAME) \
		--stack-name $(PRIVATELINK_NLB_MODULES_STACK_NAME) \
		--no-fail-on-empty-changeset \
		--parameter-overrides \
			"Environment=$(AWS_ENVIRONMENT)" \
			"NLBConfigDetails=wm-common-vpc-endpoints-private-link-nlbs" \
			"NLBArn=/$(AWS_ENVIRONMENT)/wm-common-vpc-endpoints-private-link-nlb-arn" \
		--tags \
			"Contact=$(CONTACT)" \
			"Environment=$(AWS_ENVIRONMENT)" \
			"Name=$(PRIVATELINK_NLB_MODULES_STACK_NAME)" \
			"BusinessUnit=$(BUSINESS_UNIT)" \
			"ProjectCode=$(PROJECT_CODE)"

	@aws cloudformation update-termination-protection \
		--region $(AWS_REGION) \
		--stack-name $(PRIVATELINK_NLB_MODULES_STACK_NAME) \
		--enable-termination-protection

deploy_wm_privatelink_security: wm_privatelink_security $(DRYRUN_TARGETS_WM_PRIVATE_LINK_SECURITY) print_stack_outputs_$(WM_PRIVATE_LINK_SECURITY_STACK_NAME)

wm_privatelink_security:  ## Deploy private link security CF stack to an AWS_ENVIRONMENT of your choice
	@$(DEPLOY_COMMAND) \
		--region $(AWS_REGION) \
		--template-file $(WM_PRIVATE_LINK_SECURITY_TEMPLATE_NAME) \
		--stack-name $(WM_PRIVATE_LINK_SECURITY_STACK_NAME) \
		--no-fail-on-empty-changeset \
		--parameter-overrides \
			"Environment=$(AWS_ENVIRONMENT)" \
		--tags \
			"Contact=$(CONTACT)" \
			"Environment=$(AWS_ENVIRONMENT)" \
			"Name=$(WM_PRIVATE_LINK_SECURITY_STACK_NAME)" \
			"BusinessUnit=$(BUSINESS_UNIT)" \
			"ProjectCode=$(PROJECT_CODE)"

	@aws cloudformation update-termination-protection \
		--region $(AWS_REGION) \
		--stack-name $(WM_PRIVATE_LINK_SECURITY_STACK_NAME) \
		--enable-termination-protection

deploy_cw_logs_resource_policy: cw_logs_resource_policy $(DRYRUN_TARGETS_CW_LOGS_RESOURCE_POLICY) print_stack_outputs_$(DRYRUN_TARGETS_CW_LOGS_RESOURCE_POLICY)

cw_logs_resource_policy:  ## Deploy CloudWatch Logs Resource Policy CF stack to an AWS_ENVIRONMENT of your choice
	@$(DEPLOY_COMMAND) \
		--region $(AWS_REGION) \
		--template-file $(CW_LOGS_RESOURCE_POLICY_TEMPLATE_NAME) \
		--stack-name $(CW_LOGS_RESOURCE_POLICY_STACK_NAME) \
		--no-fail-on-empty-changeset \
		--parameter-overrides \
			"Environment=$(AWS_ENVIRONMENT)" \
		--tags \
			"Contact=$(CONTACT)" \
			"Environment=$(AWS_ENVIRONMENT)" \
			"Name=$(CW_LOGS_RESOURCE_POLICY_STACK_NAME)" \
			"BusinessUnit=$(BUSINESS_UNIT)" \
			"ProjectCode=$(PROJECT_CODE)"

	@aws cloudformation update-termination-protection \
		--region $(AWS_REGION) \
		--stack-name $(CW_LOGS_RESOURCE_POLICY_STACK_NAME) \
		--enable-termination-protection

# --------------------------------------------------------
# Required parameters:
# AWS_ENVIRONMENT - one of dev/prod/uat/infng3rd/etc.
# PRIVATELINK_CONNECTION_NAME - Name of sub folder to use in networking/privatelink/producers
# PRIVATELINK_ENDPOINT_SERVICE_NAME - the endpoint service name with which we are integrating
#
# Example: to deploy the snowflake nonprod producer stack to the infng3rdp environment, run:
# $ export AWS_ENVIRONMENT=infng3rdp PRIVATELINK_CONNECTION_NAME=infng3rdp-snowflake-prod
# $ make deploy_privatelink_consumer
# You will need Full/Network admin permissions
# -------------------------------------------------------
deploy_privatelink_consumer: privatelink_consumer $(DRYRUN_TARGETS_PRIVATELINK_CONSUMER) privatelink_consumer_create_tags print_stack_outputs_$(DRYRUN_TARGETS_PRIVATELINK_CONSUMER)

privatelink_consumer:  ## Deploy PrivateLink Consumer CF stack to an AWS_ENVIRONMENT of your choice
	@$(DEPLOY_COMMAND) \
		--region $(AWS_REGION) \
		--template-file $(PRIVATELINK_CONSUMER_TEMPLATE_NAME) \
		--stack-name $(PRIVATELINK_CONSUMER_STACK_NAME) \
		--no-fail-on-empty-changeset \
		--parameter-overrides \
			"Environment=$(AWS_ENVIRONMENT)" \
			"PrivateLinkConnectionName=$(PRIVATELINK_CONNECTION_NAME)" \
			"PrivateLinkEndpointServiceName=$(PRIVATELINK_ENDPOINT_SERVICE_NAME)" \
		--tags \
			"Contact=$(CONTACT)" \
			"Environment=$(AWS_ENVIRONMENT)" \
			"Name=$(PRIVATELINK_CONSUMER_STACK_NAME)" \
			"BusinessUnit=$(BUSINESS_UNIT)" \
			"ProjectCode=$(PROJECT_CODE)"

	@aws cloudformation update-termination-protection \
		--region $(AWS_REGION) \
		--stack-name $(PRIVATELINK_CONSUMER_STACK_NAME) \
		--enable-termination-protection


privatelink_consumer_create_tags:  ## Create tags for privatelink consumer vpc endpoint as not supported by CF
	$(eval VPC_ENDPOINT_ID := \
		$(shell \
			aws cloudformation describe-stacks \
				--region $(AWS_REGION) \
				--stack-name $(PRIVATELINK_CONSUMER_STACK_NAME) \
				--query "Stacks[0].Outputs[?OutputKey=='VPCEndpointId'].OutputValue" \
				--output text \
	))
	@aws ec2 create-tags \
		$(DRYRUN_PRIVATELINK_CONSUMER_CRETE_TAGS) \
		--resources $(VPC_ENDPOINT_ID) \
		--tags Key=Name,Value=$(PRIVATELINK_CONSUMER_STACK_NAME)

# To be executed in the account where the Privatelink and PrivateDNS exist (Infrastucture NG account)
privatelink_consumer_private_dns_athorization:  ## Authorize the VPCs in the Network account to resolve Private DNS
	$(eval PRIVATE_HOSTED_ZONE_ID := \
		$(shell \
			aws cloudformation describe-stacks \
				--region $(AWS_REGION) \
				--stack-name $(PRIVATELINK_CONSUMER_STACK_NAME) \
				--query "Stacks[0].Outputs[?OutputKey=='PrivateHostedZoneId'].OutputValue" \
				--output text \
	))
	@for pair in $(PRIVATELINK_AUTHORIZATION_VPC_PAIRS); do \
		VPCRegion=$$(echo $$pair | cut -d',' -f1); \
		VPCId=$$(echo $$pair | cut -d',' -f2); \
		echo "Creating VPC association authorization for $$VPCRegion and $$VPCId in $$PRIVATE_HOSTED_ZONE_ID"; \
		aws route53 create-vpc-association-authorization \
		--hosted-zone-id $(PRIVATE_HOSTED_ZONE_ID) \
		--vpc VPCRegion=$$VPCRegion,VPCId=$$VPCId \
		--region $(AWS_REGION); \
	done

# To be executed in the Network account
privatelink_consumer_private_dns_vpc_association:  ## Associate the VPCs in the Network account to resolve Private DNS
	@for pair in $(PRIVATELINK_AUTHORIZATION_VPC_PAIRS); do \
		VPCRegion=$$(echo $$pair | cut -d',' -f1); \
		VPCId=$$(echo $$pair | cut -d',' -f2); \
		echo "Creating VPC association for $$VPCRegion and $$VPCId with $$PRIVATE_HOSTED_ZONE_ID"; \
		aws route53 associate-vpc-with-hosted-zone \
		--hosted-zone-id $(PRIVATE_HOSTED_ZONE_ID) \
		--vpc VPCRegion=$$VPCRegion,VPCId=$$VPCId \
		--region $(AWS_REGION); \
	done

# --------------------------------------------------------
# Required parameters:
# AWS_ENVIRONMENT - one of dev/prod/uat/infng3rd/etc.
# PRIVATELINK_CONNECTION_NAME - Name of sub folder to use in networking/privatelink/producers
#
# Example: to deploy the ataccama nonprod producer stack to the infng3rdp environment, run:
# $ export AWS_ENVIRONMENT=infng3rdp PRIVATELINK_CONNECTION_NAME=infng3rdp-ataccama-nonprod
# $ make deploy_privatelink_producer
# -------------------------------------------------------
deploy_privatelink_producer: privatelink_producer $(DRYRUN_TARGETS_PRIVATELINK_PRODUCER) privatelink_producer_create_tags print_stack_outputs_$(DRYRUN_TARGETS_PRIVATELINK_PRODUCER)

privatelink_producer:  ## Deploy PrivateLink Producer CF stack to an AWS_ENVIRONMENT of your choice
	@$(DEPLOY_COMMAND) \
		--region $(AWS_REGION) \
		--template-file $(PRIVATELINK_PRODUCER_TEMPLATE_NAME) \
		--stack-name $(PRIVATELINK_PRODUCER_STACK_NAME) \
		--capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND \
		--no-fail-on-empty-changeset \
		--parameter-overrides \
			"Environment=$(AWS_ENVIRONMENT)" \
			"PrivateLinkConnectionName=$(PRIVATELINK_CONNECTION_NAME)" \
		--tags \
			"Contact=$(CONTACT)" \
			"Environment=$(AWS_ENVIRONMENT)" \
			"Name=$(PRIVATELINK_PRODUCER_STACK_NAME)" \
			"BusinessUnit=$(BUSINESS_UNIT)" \
			"ProjectCode=$(PROJECT_CODE)"

	@aws cloudformation update-termination-protection \
		--region $(AWS_REGION) \
		--stack-name $(PRIVATELINK_PRODUCER_STACK_NAME) \
		--enable-termination-protection

privatelink_producer_create_tags:  ## Create tags for privatelink consumer vpc endpoint as not supported by CF
	$(eval VPC_ENDPOINT_SERVICE_ID := \
		$(shell \
			aws cloudformation describe-stacks \
				--region $(AWS_REGION) \
				--stack-name $(PRIVATELINK_PRODUCER_STACK_NAME) \
				--query "Stacks[0].Outputs[?OutputKey=='VPCEndpointServiceId'].OutputValue" \
				--output text \
	))
	@aws ec2 create-tags \
		$(DRYRUN_PRIVATELINK_PRODUCER_CRETE_TAGS) \
		--resources $(VPC_ENDPOINT_SERVICE_ID) \
		--tags Key=Name,Value=$(PRIVATELINK_PRODUCER_STACK_NAME)

deploy_vpc_endpoints: vpc_endpoints $(DRYRUN_TARGETS_VPC_ENDPOINTS) print_stack_outputs_$(DRYRUN_TARGETS_VPC_ENDPOINTS)

vpc_endpoints:  ## Deploy VPC Endpoints stack to an AWS_ENVIRONMENT of your choice
	@$(DEPLOY_COMMAND) \
		--region $(AWS_REGION) \
		--template-file $(VPC_ENDPOINTS_TEMPLATE_NAME) \
		--stack-name $(VPC_ENDPOINTS_STACK_NAME) \
		--no-fail-on-empty-changeset \
		--parameter-overrides \
			"Environment=$(AWS_ENVIRONMENT)" \
		--tags \
			"Contact=$(CONTACT)" \
			"Environment=$(AWS_ENVIRONMENT)" \
			"Name=$(VPC_ENDPOINTS_STACK_NAME)" \
			"BusinessUnit=$(BUSINESS_UNIT)" \
			"ProjectCode=$(PROJECT_CODE)"

	@aws cloudformation update-termination-protection \
		--region $(AWS_REGION) \
		--stack-name $(VPC_ENDPOINTS_STACK_NAME) \
		--enable-termination-protection

# --------------------------------------------------------
# This is for deploying AWS Service Managed Endpoints
# Required parameters:
# AWS_REGION - aws region for the stack deployment
# AWS_ENVIRONMENT - one of curationdev/curationuat/curationprod/dev/etc.
# AWS_SERVICE_NAME - AWS service name, ie: redshift, s3, etc.

deploy_awsservice_endpoints: aws_service_endpoints $(DRYRUN_TARGETS_AWSSERVICE_ENDPOINTS) print_stack_outputs_$(DRYRUN_TARGETS_AWSSERVICE_ENDPOINTS)

aws_service_endpoints:  ## Deploy AWS Service Managed Enpoint's stack to an AWS_ENVIRONMENT of your choice
	@$(DEPLOY_COMMAND) \
		--region $(AWS_REGION) \
		--template-file $(AWSSERVICE_ENDPOINTS_TEMPLATE_NAME) \
		--stack-name $(AWSSERVICE_ENDPOINTS_STACK_NAME) \
		--no-fail-on-empty-changeset \
		--parameter-overrides \
			"Environment=$(AWS_ENVIRONMENT)" \
		--tags \
			"Contact=$(CONTACT)" \
			"Environment=$(AWS_ENVIRONMENT)" \
			"Name=$(AWSSERVICE_ENDPOINTS_STACK_NAME)" \
			"BusinessUnit=$(BUSINESS_UNIT)" \
			"ProjectCode=$(PROJECT_CODE)"

	@aws cloudformation update-termination-protection \
		--region $(AWS_REGION) \
		--stack-name $(AWSSERVICE_ENDPOINTS_STACK_NAME) \
		--enable-termination-protection

# --------------------------------------------------------
# Required parameters:
# AWS_ENVIRONMENT - one of dev/prod/uat/infng3rd/etc.
# AWS_ACCOUNT_ALIAS - AWS Account alias, eg woodmac-non-prod
# VPC_CIDR - CIDR Range for the VPC
# PRIVATE_APP_SUBNET_01 - CIDR range for PrivatgeAppSubnet1
# PRIVATE_APP_SUBNET_02 - CIDR range for PrivateAppSubnet02
# PRIVATE_DB_SUBNET_01 - CIDR range for PrivateDBSubnet01
# PRIVATE_DB_SUBNET_02 - CIDR range for PrivateDBSubnet02
# PRIVATE_WEB_SUBNET_01 - CIDR range for PrivateWebSubnet01
# PRIVATE_WEB_SUBNET_02 - CIDR range for PrivateWebSubnet02
# PUBLIC_WEB_SUBNET_01 - CIDR range for PublicWebSubnet01
# PUBLIC_WEB_SUBNET_02 - CIDR range for PublicWebSubnet02

# Optional parameters:
# ATTACH_TO_CWAN - `true` or `false` by default `false`
# CWAN_SEGMENT - `ghost`, `transit`, `management`, `managementnonprod`, `prod`, `nonprod`, `prodrestricted` by default `ghost`
#
# Example: to deploy the a test sandbox environment, run:
# Optional exports with cwan attachment
# $ export ATTACH_TO_CWAN=true
# $ export CWAN_SEGMENT=nonprod
# Deploment
# $ export AWS_ENVIRONMENT=sandbox \
# > AWS_REGION=us-east-1 \
# > AWS_ACCOUNT_ALIAS=woodmac-test \
# > VPC_CIDR=10.92.128.0/22 \
# > PUBLIC_WEB_SUBNET_01=10.92.128.0/25 \
# > PUBLIC_WEB_SUBNET_02=10.92.128.128/25 \
# > PRIVATE_WEB_SUBNET_01=10.92.129.0/25 \
# > PRIVATE_WEB_SUBNET_02=10.92.129.128/25 \
# > PRIVATE_APP_SUBNET_01=10.92.130.0/25 \
# > PRIVATE_APP_SUBNET_02=10.92.130.128/25 \
# > PRIVATE_DB_SUBNET_01=10.92.131.0/25 \
# > PRIVATE_DB_SUBNET_02=10.92.131.128/25
# $ make deploy_vpc_type_1
# -------------------------------------------------------

deploy_vpc_type_1: vpc_type_1 $(DRYRUN_TARGETS_VPC_TYPE_1) print_stack_outputs_$(DRYRUN_TARGETS_VPC_TYPE_1)

vpc_type_1:  ## Deploy VPC Type 1
	@$(DEPLOY_COMMAND) \
		--region $(AWS_REGION) \
		--template-file $(VPC_TYPE_1_TEMPLATE_NAME) \
		--stack-name $(VPC_TYPE_1_STACK_NAME) \
		--no-fail-on-empty-changeset \
		--parameter-overrides \
			"Environment=$(AWS_ENVIRONMENT)" \
			"AccountAlias=$(AWS_ACCOUNT_ALIAS)" \
			"VpcCIDR=$(VPC_CIDR)" \
			"PublicWebSubnet01=$(PUBLIC_WEB_SUBNET_01)" \
			"PublicWebSubnet02=$(PUBLIC_WEB_SUBNET_02)" \
			"PrivateWebSubnet01=$(PRIVATE_WEB_SUBNET_01)" \
			"PrivateWebSubnet02=$(PRIVATE_WEB_SUBNET_02)" \
			"PrivateAppSubnet01=$(PRIVATE_APP_SUBNET_01)" \
			"PrivateAppSubnet02=$(PRIVATE_APP_SUBNET_02)" \
			"PrivateDBSubnet01=$(PRIVATE_DB_SUBNET_01)" \
			"PrivateDBSubnet02=$(PRIVATE_DB_SUBNET_02)" \
			"CloudWANAttachment=$(ATTACH_TO_CWAN)" \
			"CloudWANSegment=$(CWAN_SEGMENT)" \
		--tags \
			"Contact=$(CONTACT)" \
			"Environment=$(AWS_ENVIRONMENT)" \
			"Name=$(VPC_TYPE_1_STACK_NAME)" \
			"BusinessUnit=$(BUSINESS_UNIT)" \
			"ProjectCode=$(PROJECT_CODE)"

	@aws cloudformation update-termination-protection \
		--region $(AWS_REGION) \
		--stack-name $(VPC_TYPE_1_STACK_NAME) \
		--enable-termination-protection

change_set_%: ## Get the latest changeset for a stack (change_set_stack-name)
	$(eval CHANGE_SET := \
		$(shell \
			aws cloudformation list-change-sets \
				--region $(AWS_REGION) \
				--stack-name $* \
				--output json \
				| jq '.Summaries | max_by(.CreationTime) | .ChangeSetId' \
	))
	@aws cloudformation describe-change-set \
		--region $(AWS_REGION) \
		--change-set-name $(CHANGE_SET) \
		--output json \
		| jq '.'

print_stack_outputs_%: ## print the stack outputs for a stack (print_stack_outputs-stack-name)
	@aws cloudformation describe-stacks \
		--region $(AWS_REGION) \
		--stack-name $* \
		--query "Stacks[0].Outputs" \
		--output json \
		| jq '.'

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
