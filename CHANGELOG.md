## 1.3.0 (April 12, 2024)
FEATURES:
* feat: add variable zonal_asg_enabled boolean. Expectations:
    - If false, then create only one Auto Scaling Group for all availability zones inputted per var.cc_subnet_ids
    - If true, then create one Auto Scaling Group per subnet availability zones inputted
    - Note: Single ASG is simpler to manage and recommended especially when enabling cross-zone gateway load balancing. ASG per AZ may be desirable for more consistent and granular control over scaling in/out.
* feat: add all capacity and warm pool metrics to Auto Scaling Group enabled_metrics
* feat: add zsec support for regions: ap-southeast-3, me-central-1, eu-central-2, and il-central-1
* feat: add variables support_access_enabled and zssupport_server for Zscaler Remote Support Tunnel enablement
* feat: changed variable health_check_grace_period to 900 seconds to prevent instance termination in Auto Scaling Group when moved into InService even if its is found as unhealthy.  Currently CC/ZTW VM requires more time for health stabilization at startup.
* feat: Changed Python runtime for Lambda to use 3.12 version. arm64 architecture is now supported and is new default.  This is more for cost/peformance benefit.

ENHANCEMENTS:
* feat: ASG bring-up/stability improvements with new [Zscaler Lambda Zip file v1.0.6](modules/terraform-zscc-asg-lambda-aws/zscaler_cc_lambda_service.zip)
* feat: user selection prompt for Zscaler cloud. Used for template validation and DNS lookup FQDN-to-IP mapping for security group rule creation
* refactor: add prompt to enable/disable Zscaler Remote Support security group egress rule
* feat: ZSEC bash script prompts for Auto Scaling Group zonal configuration
* refactor: ZSEC bash script UI/UX and error handling improvements
    - Auto parse MFA STS output values
    - Discover/prompt for different local AWS config profiles
    - Improved selection constraints for regions and EC2 types
    - Add Zscaler Cloud selection for SG generation
* refactor: update AWS Provider default to 5.39.1 with minimum supported 5.32.0 (required for ASG/Lambda configurations)
* docs: general UX improvements

BUG FIXES:
* fix: add variable cc_route_table_enabled for conditional creation of aws_route_table.cc_rt and aws_route_table_association.cc_rt_asssociation. This is to avoid conflicts for brownfield VPC requirements where a custom subnet route table already exists to just tell terraform not to implicitly create a new one
* fix: workload/bastion AWS al2 to al2023

## v1.2.2 (March 8, 2024)
ENHANCEMENTS:
* refactor: add zsec support for AWS Region il-central-1

## v1.2.1 (February, 3, 2024)
BUG FIXES:
* fix: remove var.gwlb_enabled condition for ingress_cc_service_all
* fix: add ingress rule ingress_cc_service_https_local for default implicit TCP/443 communication minimum between Cloud Connector Service Interfaces within a VPC cluster

## v1.2.0 (December 16, 2023)
FEATURES:
* feat: add optional cc_tags IAM Policy for AWS Workload Tags support with Cloud Connector Instance IAM Role creation. Permissions include:
    - sqs:DeleteMessage
    - sqs:ReceiveMessage
    - sqs:GetQueueUrl
    - sqs:GetQueueAttributes
    - sqs:SetQueueAttributes
    - sqs:DeleteQueue
    - sqs:CreateQueue
    - sns:Subscribe
 * feat: add conditional variable cloud_tags_enabled

ENHANCEMENTS:
* refactor: ZSEC bash script prompts for cloud workload tagging policy creation
* refactor: add greenfield/pov workload ZS Root CA install

## v1.1.0 (November 3, 2023)
FEATURES:
* AWS GovCloud (US) support

BUG FIXES:
* fix: arn support for all aws partitions

ENHANCEMENTS:
* ZSEC bash script support for automatic aws partition selection for MFA
* ZSEC general cleanup and optimizations

## v1.0.0 (October 19, 2023)
BREAKING CHANGES:
* Zscaler Cloud Connector AMI version > ZS6.1.25.0 support for default interface swap of both autoscaling and non-autoscaling deployments. Service interface is now ENA0 and Management interface is now ENA1. 

FEATURES:
* Auto Scaling Group official release
    - add: terraform-zscc-asg-aws module
    - add: terraform-zscc-asg-labda-aws module
    - change: IAM policies for ASG lifecycle and Cloudwatch metrics
    - add: deployment types base_cc_gwlb_asg/base_cc_gwlb_asg_zpa (greenfield/pov/test) and cc_gwlb_asg (brownfield/prod)
* Medium and Large Cloud Connector instance official release
* EC2 instance type changes:
    - new default/recommend EC2 type for small CCs: m6i.large; medium/large: m6i.4xlarge
    - add: m5n, m6i, and c6i family support
    - remove: m5 family support
* Module Changes:
    - AWS Provider version bump to 5.17.x default. Support from 4.59.x to 5.17.x
    - terraform-zscc-ccvm-aws:
        - rename: service_eni_1 output to management_eni
        - rename: private_ip output to forwarding_ip
        - rename: cc_service_private_ip to management_ip
        - add: forwarding_eni
    - module terraform-zscc-gwlb-aws:
        - add: variable asg_enabled for target group conditional instance rather than ip
        - rename: resource aws_lb_target_group_attachment.gwlb_target_group_attachment_small to aws_lb_target_group_attachment.gwlb_target_group_attachment
        - rename: variable cc_small_service_ips to cc_service_ips
        - remove: dedicated CC Medium/Large additional service IP dependencies from target group attachment
    - module terraform-zscc-ccvm-aws:
        - remove: secondary IP address from network interface index #1
        - add: interface device index #5 for "large" CC.
        - add: aws_network_interface.cc_vm_nic_index_0 for interface swap support
    - module terraform-zscc-gwlbendpoint-aws:
        - add: outputs vpce_service_id
        - add: outputs vpce_service_arn
    - module terraform-zscc-sg-aws:
        - refactor: management and service security group with more granular/required rules
        - add: variable mgmt_ssh_enabled if customer wants to restrict management access to only SSM
        - add: variable http_probe_port
        - add: gwlb_enabled default to true
        - add: all_ports_egress_enabled default to true
    - module terraform-zscc-iam-aws:
        - add: cc_metrics_policy_document permissions to CC IAM Role
        - add: cc_autoscale_lifecycle_policy_document permissions to CC IAM Role
        - remove: cc_callhome_policy_document as no longer required
* ZSEC support for AWS region ap-south-2 (Hyderabad)

ENHANCEMENTS:
* ZSEC bash script inputs for ASG deployments
* ZSEC bash script inputs for brownfield/byo network environments
* CC VM EBS changes: Volume type default now gp3 and AWS KMS encryption support enabled by default

## v0.2.0 (June 20, 2023)
* AWS Provider updated from 4.7.x to 4.59.x for all example templates and child modules
* terraform-zscc-gwlb-aws custom gwlb_name and target_group_name variables added
* name_prefix variable default string changed from zsdemo to zscc
* validation length constraint added to name_prefix variable
* dependency fixes for vpc/subnet data resource selection when vpc was originally created with example templates
* GWLB default changes/new features: 
    - Enable rebalance default
    - flow stickiness selection capability
    - deregistration delay changed to 0 from default 300
    - healthy_threshold lowered from 3 to 2
* new list(string) variable ami_id to enable custom deployments/granular upgrade scenarios
    - moved latest AMI ID lookup from ccvm module to parent/main.tf
* service network interface data source replaced with resource for terraform-zscc-ccvm-aws outputs
* replace default secretsmanager policy with custom least privilege CCPermitGetSecrets with only required GetSecretValue access to the Secret Manager name specified
* IMDSv2 required by default for Cloud Connector EC2 instance creation. imdsv2_enabled variable added to terraform-zscc-ccvm-aws module
* CC mgmt/service security group lifecycle and dependency fixes
* replace default secretsmanager policy with custom least privilege CCPermitGetSecrets with only required GetSecretValue access to the Secret Manager name specified
* IMDSv2 required by default for Cloud Connector EC2 instance creation. imdsv2_enabled variable added to terraform-zscc-ccvm-aws module
* CC mgmt/service security group lifecycle and dependency fixes

## v0.1.0 (December 15, 2022) 
* github release refactor from Cloud Connector Portal
* zsec update for terraform support up to 1.1.9 and aws provider 4.7.x
* zsec updated with mac m1 option for terraform arm64 version download
* modules renamed for granularity and consistency
* CC IAM and Security Group resources broken out to individual child modules
* Support for reusing the same IAM and Security Group resources for all CC VMs.
* Bring your own IAM Instance Profile and Security Groups available for brownfield/custom deployments
* terraform-zscc-lambda-aws module - fix for lambda deployments containing only 1 CC subnet
* move provider details to versions.tf
* added TF_DATA_DIR to zsec and backend.tf to each deployment type to maintain root path as "examples/" directory for all deployments
* renamed cc_custom to cc_ha
* renamed cc_gwlb_custom to cc_gwlb
* added bastion source ssh security group option
* add auto acceptance and allowed_principals capability to terraform-zscc-gwlbendpoint-aws module. Default to auto accept restricting to user's Account ID
* moved all network infrastructure resources (vpc, IGW, NAT Gateway, subnets, route tables, etc.) to unique module terraform-zscc-network-aws
* added custom subnet definition capabilities via variables cc_subnets, route53_subnets, public_subnets, and workloads_subnets should customer try to override vpc_cidr and the auto cidrsubnet selection becomes incompatible
* workload and bastion modules changed to AL2 EC2 to enable SSM and require IMDSv2 metadata
* cc-error-checker changes to run first so errors thrown are less and clearer in the event of a CC deployment configuration error
* ASG module + deployment types added
* Support for M/L CC GWLB non-ASG
* SSM policy modified for least privilege
* IAM policy for ASG Lifecycle completion
