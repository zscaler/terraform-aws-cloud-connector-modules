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
* Support for M/L CC GWLB non-ASG
* SSM policy modified for least privilege
