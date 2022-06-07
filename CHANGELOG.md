## 1.2.0 (May 5, 2022)
NOTES:
* Zscaler Cloud Connector ZPA/Route 53 improvements
* terraform-zscc-aws updated to output private IP for all potential network interfaces (medium/large support)
* terraform-zsgwlb-aws updated to support dynamically attaching additional CC interface IPs to GWLB Target Group
* gwlb module variables updated to accept all possible CC service nic quantities

BUG FIXES:
* BUG-120021 - Default domains added to SYSTEM Route 53 Resolver rules for ZPA based deployments
* BUG-120791 - GWLB support for Medium/Large Cloud Connector deployments

Enhancements:
* target_address variable updated with two Zscaler Global VIPs per https://config.zscaler.com/zscaler.net/cenr
* zscaler_domains variable added to terraform-zsroute53-aws module for default SYSTEM rules

ENHANCEMENTS:
* cc_callhome_enabled variable added
* terraform-zscc-aws module IAM Role definitions refined and include cc-callhome-policy option. Enabled by default, deployed Cloud Connectors will be able to send diagnostics and logs to Zscaler to assist with any deployment issues or debug support. The IAM Role ARN needs to be provided after creation to Zscaler for IAM trust relationship


## 1.1.1 (March 25, 2022)
NOTES:
* write testbed.txt file to root directory from deployment type output.tf

BUG FIXES:
* BUG-118473 - variable cross_zone_lb_enabled added to terraform-zsgwlb-aws aws_lb resource

## 1.1.0 (March 7, 2022)
NOTES:
* change default ccvm_instance_type to m5.large; added 2xlarge and 4xlarge options for different CC sizes
* consolidate CC service and management defaults to a single subnet + expanded to /24 default
* update AWS provider to latest stable w/ GWLB resource support
* general cleanup: variables, syntax, readme updates, zsec


ENHANCEMENTS:
* ZS-16589 - GWLB support added: new greenfield deployment types (base_cc_gwlb and base_cc_gwlb_zpa) and modules (terraform-zsgwlbendpoint-aws and terraform-zsgwlb-aws)
* BUG-95033 - Brownfield/custom deployment types available: cc_custom and cc_gwlb_custom deployment templates added. terraform.tfvars updated with bring-your-own resource logic
* BUG-115143 - locals variable to validate ccvm_instance_size is compatible with cc_instance_size
* EIO-1417 - cc_instance_size variable added for small/medium/large. Number of CC service nics automatically adjusts based on this variable definition.
* create 1 NAT GW + EIP per CC subnet/AZ in separate public subnet AZs for multi-CC deployments
* create separate security group for management and service interfaces
* aws ssh key generation removed from zsec and added natively to terraform via tls_private_key resource
* az_count, cc_count, and workload_count variables added to provide easier scaling and less module duplication
* added global_tags in addition to static Name tag on all tagged resources
* zpa_enabled variable for brownfield deployment types to toggle creation of route53 resources with deployment
* lambda_enabled variable for brownfield deployment types to toggle creation of lambda resources with deployment


BUG FIXES:
* ZPA module enhancements for rule mapping to multiple domain name inputs
* dynamic IP address iterator for route 53 resolver endpoint subnets
* lambda spacing fix for multiple route table IDs
* tags map cleanup for newer TF version compatibility and customizable tag attributes


## 1.0.3 (January 19, 2022)
BUG FIXES:
* BUG-110673 - name-prefix append "-workload1" for consistency between base1 and base2 deployment types
* BUG-111245 - R53 route table fix for secondary Outbound Endpoint affix to secondary subnet
* BUG-111245 - Added second workload module and R53 route table and association for base_2cc_zpa to match base_2cc. Updated outputs to reflect new workloads
* BUG-111245 - Updated Lambda module for base_2cc_zpa to match base_2cc
* BUG-111245 - Updated subnet-count default from 1 to 2 for base_2cc_zpa to match base_2cc additional workloads provisioned
* BUG-110694 - Address Terraform destroy issues with Macs specifying different terraform working directory

NOTES:
* TF description and AWS tag/mapping description cleanup


## 1.0.2 (October 25, 2021)
BUG FIXES:
* ccvm-instance-size variable renamed to ccvm-instance-type in terraform.tfvars

## 1.0.1 (October 1, 2021)
ENHANCEMENTS:
* Cloud Connector Service Interface secondary private IP + Name/description mapping added


## 1.0.0 (August 24, 2021)
NOTES:
* Initial code revision check-in

ENHANCEMENTS:
* terraform.tfvars additions: http-probe-port (for CC listener service + health probing); cc_vm_prov_url and secret_name variables for dynamic user_data file creation; ccvm-instance-type for AWS VM size selections

FEATURES:
* Customer solutioned POV template for greenfield/brownfield AWS Cloud Connector Deployments
* Sanitized README file
* ZSEC updated for deployment selection on destroy
* local file user_data file creation with variable reference for cloud init provisioning
* conditional constraints added for new VM types supported: t3.medium, t2.medium, m5.large, c5.large, and c5a.large

BUG FIXES: 
* Outputs testbed EC SSH syntax fixes
