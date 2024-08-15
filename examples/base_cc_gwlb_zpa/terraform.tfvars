## This is only a sample terraform.tfvars file.
## Uncomment and change the below variables according to your specific environment

#####################################################################################################################
##### Variables are populated automically if terraform is ran via ZSEC bash script.   ##### 
##### Modifying the variables in this file will override any inputs from ZSEC         #####
#####################################################################################################################

#####################################################################################################################
##### Cloud Init Userdata Provisioning variables  #####
#####################################################################################################################

## 1. Zscaler Cloud Connector Provisioning URL E.g. connector.zscaler.net/api/v1/provUrl?name=aws_prov_url

#cc_vm_prov_url                             = "connector.zscaler.net/api/v1/provUrl?name=aws_prov_url"

## 2. AWS Secrets Manager Secret Name from Secrets Manager E.g ZS/CC/credentials

#secret_name                                =  "ZS/CC/credentials/aws_cc_secret_name"

## 3. Cloud Connector cloud init provisioning listener port. This is required for GWLB and Health Probe deployments. 
## Uncomment and set custom probe port to a single value of 80 or any number between 1024-65535. Default is 50000.

#http_probe_port                            = 50000


#####################################################################################################################
##### Custom variables. Only change if required for your environment  #####
#####################################################################################################################

## 4. The name string for all Cloud Connector resources created by Terraform for Tag/Name attributes. (Default: zscc)

#name_prefix                                = "zscc"

## 5. AWS region where Cloud Connector resources will be deployed. This environment variable is automatically populated if running ZSEC script
##    and thus will override any value set here. Only uncomment and set this value if you are deploying terraform standalone. (Default: us-west-2)

#aws_region                                 = "us-west-2"

## 6. Cloud Connector AWS EC2 Instance size selection. Uncomment ccvm_instance_type line with desired vm size to change.
##    (Default: m6i.large)

#ccvm_instance_type                         = "t3.medium"
#ccvm_instance_type                         = "m5n.large"
#ccvm_instance_type                         = "c5a.large"
#ccvm_instance_type                         = "m6i.large"
#ccvm_instance_type                         = "c6i.large"
#ccvm_instance_type                         = "c6in.large"
#ccvm_instance_type                         = "m5n.4xlarge"
#ccvm_instance_type                         = "m6i.4xlarge"
#ccvm_instance_type                         = "c6i.4xlarge"
#ccvm_instance_type                         = "c6in.4xlarge"

## 7. Cloud Connector Instance size selection. Uncomment cc_instance_size line with desired vm size to change
##    (Default: "small") 
##    **** NOTE - There is a dependency between ccvm_instance_type and cc_instance_size selections ****
##    If size = "small" any supported EC2 instance type can be deployed, but "m6i/c6i.large" is ideal
##    If size = "medium" only 4xlarge and up EC2 instance types can be deployed
##    If size = "large" only 4xlarge EC2 instane types can be deployed 
##    **** NOTE - medium and large cc_instance_size is only supported with GWLB deployments. Legacy HA/Lambda deployments must be small.

#cc_instance_size                           = "small"
#cc_instance_size                           = "medium"
#cc_instance_size                           = "large" 

## 8. The number of Cloud Connector Subnets to create in sequential availability zones. Available input range 1-3 (Default: 2)
##    **** NOTE - This value will be ignored if byo_vpc / byo_subnets

#az_count                                   = 2

## 9. The number of Cloud Connector appliances to provision. Each incremental Cloud Connector will be created in alternating 
##    subnets based on the az_count or byo_subnet_ids variable and loop through for any deployments where cc_count > az_count.
##    (Default: varies per deployment type template)
##    E.g. cc_count set to 4 and az_count set to 2 or byo_subnet_ids configured for 2 will create 2x CCs in AZ subnet 1 and 2x CCs in AZ subnet 2

#cc_count                                   = 2

## 10. Network Configuration:
##    IPv4 CIDR configured with VPC creation. All Subnet resources (Workload, Public, Cloud Connector, Route 53) will be created based off this prefix
##    /24 subnets are created assuming this cidr is a /16. If you require creating a VPC smaller than /16, you may need to explicitly define all other 
##     subnets via public_subnets, workload_subnets, cc_subnets, and route53_subnets variables

##    Note: This variable only applies if you let Terraform create a new VPC. Custom deployment with byo_vpc enabled will ignore this

#vpc_cidr                                   = "10.1.0.0/16"

##    Subnet space. (Minimum /28 required. Default is null). If you do not specify subnets, they will automatically be assigned based on the default cidrsubnet
##    creation within the VPC CIDR block. Uncomment and modify if byo_vpc is set to true but byo_subnets is left false meaning you want terraform to create 
##    NEW subnets in that existing VPC. OR if you choose to modify the vpc_cidr from the default /16 so a smaller CIDR, you may need to edit the below variables 
##    to accommodate that address space.

##    ***** Note *****
##    It does not matter how many subnets you specify here. this script will only create in order 1 or as many as defined in the az_count variable
##    Default/Minumum: 1 - Maximum: 3
##    Example: If you change vpc_cidr to "10.2.0.0/24", set below variables to cidrs that fit in that /24 like cc_subnets = ["10.2.0.0/27","10.2.0.32/27"] etc.

#public_subnets                             = ["10.x.y.z/24","10.x.y.z/24"]
#workloads_subnets                          = ["10.x.y.z/24","10.x.y.z/24"]
#cc_subnets                                 = ["10.x.y.z/24","10.x.y.z/24"]
#route53_subnets                            = ["10.x.y.z/24","10.x.y.z/24"]

## 11. Number of Workload VMs to be provisioned in the workload subnet. Only limitation is available IP space
##    in subnet configuration. Only applicable for "base" deployment types. Default workload subnet is /24 so 250 max

#workload_count                             = 2

## 12. Tag attribute "Owner" assigned to all resoure creation. (Default: "zscc-admin")

#owner_tag                                  = "username@company.com"

## 13. By default, GWLB deployments are configured as zonal. Uncomment if you want to enable cross-zone load balancing
##     functionality. Only applicable for gwlb deployment types. (Default: false)

#cross_zone_lb_enabled                      = true

## 14. Gateway loadbalancing hashing algorithm. Default is 5-tuple (None).
##     Additional options include: 2-tuple (source_ip_dest_ip) and 3-tuple (source_ip_dest_ip_proto)
##     Uncomment below the configuration you want to use.

#flow_stickiness                            = "2-tuple"
#flow_stickiness                            = "3-tuple"
#flow_stickiness                            = "5-tuple"

## 15. Indicates how the GWLB handles existing flows when a target is deregistered or marked unhealthy. 
##     true means rebalance after deregistration. false means no_rebalance. (Default: true)
##     Uncomment to turn this feature off (not recommended)

#rebalance_enabled                          = false

## 16. SSH management access from the local VPC is enabled by default (true). Uncomment if you
##     want to disable this.
##     Note: Cloud Connector will only be accessible via AWS Session Manager SSM

#mgmt_ssh_enabled                           = false

## 17. By default, a security group is created and assigned to the CC service interface(s).
##     There is an optional rule that permits Cloud Connector to forward direct traffic out
##     on all ports and protocols. (Default: true). Uncomment if you want to restrict
##     traffic to only the ZIA/ZPA required HTTPS TCP/UDP ports.

#all_ports_egress_enabled                   = false

## 18. By default, this script will apply 1 Security Group per Cloud Connector instance. 
##     Uncomment if you want to use the same Security Group for ALL Cloud Connectors (true or false. Default: false)

#reuse_security_group                       = true

## 19. By default, this script will apply 1 IAM Role/Instance Profile per Cloud Connector instance. 
##     Uncomment if you want to use the same IAM Role/Instance Profile for ALL Cloud Connectors (true or false. Default: false)

#reuse_iam                                  = true

## 20. By default, the VPC Endpoint Service created will auto accept any VPC Endpoint registration attempts.
##     Uncomment if you want to require manual acceptance. (true or false. Default: false)

#acceptance_required                        = true

## 21. By default, the VPC Endpoint Service is configured to auto accept any VPC Endpoint registration attempts from any principal in the current AWS Account.
##     Uncomment if you want to override this with more specific/restrictive principals. See https://docs.aws.amazon.com/vpc/latest/privatelink/configure-endpoint-service.html#accept-reject-connection-requests"

#allowed_principals                         = [\"arn:aws:iam::1234567890:root\"]

## 22. By default, terraform will always query the AWS Marketplace for the latest Cloud Connector AMI available.
##     This variable is provided if a customer desires to override or retain an old ami for existing deployments rather than upgrading and forcing a replacement. 
##     It is also inputted as a list to facilitate if a customer desired to manually upgrade only select CCs deployed based on the cc_count index

##     Note: Customers should NOT be hard coding AMI IDs as Zscaler recommendation is to always be deploying/running the latest version.
##           Leave this variable commented out unless you are absolutely certain why/that you need to set it and only temporarily.

#ami_id                                     = ["ami-123456789"]

## 23. By default, terraform will configure Cloud Connector with EBS encryption enabled.
##     Uncomment if you want to disable ebs encryption.

#ebs_encryption_enabled                     = false

## 24. By default, EBS encryptions is set to null which uses the AWS default managed/master key.
##     Set as 'alias/<key-alias>' to use an existing customer KMS key"

##     Note: this variable is only enforced if ebs_encryption_enabled is set to true

#byo_kms_key_alias                          = "alias/<customer key alias name>"

## 25. By default, Terraform will create an IAM policy for Cloud Connector instance(s) per
##     the terraform-zscc-iam-aws module. Optional access can be enabled for CCs to
##     subscribe to and utilize cloud workload tagging feature. Uncomment to create the 
##     cc_tags_policy IAM Policy and attach it to the CC IAM Role

##cloud_tags_enabled                        = true

## 26. By default, if Terraform is creating SGs an outbound rule is configured enabling 
##     Zscaler remote support access. Without this firewall access, Zscaler Support may not be able to assist as
##     efficiently if troubleshooting is required. Uncomment if you do not want to enable this rule.
##
##     For recommended least privilege, the rule creation is restricted to TCP destination port 12002
##     to the Support Server IP that remotesupport.<zscaler_cloud>.net resolves to. ie: if you are on
##     zscalerthree, perform a lookup for remotesupport.zscalerthree.net and update the variable
##     zssupport_server if required below.
##
##     For more information, refer to: https://config.zscaler.com/zscaler.net/cloud-branch-connector and 
##     https://help.zscaler.com/cloud-branch-connector/enabling-remote-access

#support_access_enabled                     = false
#zssupport_server                           = "199.168.148.101/32"


#####################################################################################################################
##### ZPA/Route 53 specific variables #####
#####################################################################################################################
## 27. Provide the domain names you want Route53 to redirect to Cloud Connector for ZPA interception. Only applicable for base + zpa or zpa_enabled = true
##     deployment types where Route53 subnets, Resolver Rules, and Outbound Endpoints are being created. Two example domains are populated to show the 
##     mapping structure and syntax. ZPA Module will read through each to create a resolver rule per domain_name entry. Ucomment domain_names variable and
##     add any additional appsegXX mappings as needed.

#domain_names = {
#  appseg1 = "app1.com"
#  appseg2 = "app2.com"
#}
