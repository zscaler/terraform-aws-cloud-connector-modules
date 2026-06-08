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

#secret_name                                = "ZS/CC/credentials/aws_cc_secret_name"

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
##    If size = "large" only 4xlarge EC2 instance types can be deployed
##    **** NOTE - medium and large cc_instance_size is only supported with GWLB deployments.

#cc_instance_size                           = "small"
#cc_instance_size                           = "medium"
#cc_instance_size                           = "large"

## 8. The number of Cloud Connector availability zones to deploy into. Available input range 1-3 (Default: 2)

#az_count                                   = 2

## 9. The number of Cloud Connector appliances to provision. Each incremental Cloud Connector will be created in alternating
##    subnets based on the az_count or byo_subnet_ids variable and loop through for any deployments where cc_count > az_count.
##    (Default: 2)

#cc_count                                   = 2

## 10. Tag attribute "Owner" assigned to all resource creation. (Default: "zscc-admin")

#owner_tag                                  = "username@company.com"

## 11. By default, GWLB deployments are configured as zonal. Uncomment if you want to enable cross-zone load balancing
##     functionality. (Default: false)

#cross_zone_lb_enabled                      = true

## 12. Gateway load balancing hashing algorithm. Default is 5-tuple (None).
##     Additional options include: 2-tuple (source_ip_dest_ip) and 3-tuple (source_ip_dest_ip_proto)

#flow_stickiness                            = "2-tuple"
#flow_stickiness                            = "3-tuple"
#flow_stickiness                            = "5-tuple"

## 13. Indicates how the GWLB handles existing flows when a target is deregistered or marked unhealthy.
##     true means rebalance after deregistration. false means no_rebalance. (Default: true)

#rebalance_enabled                          = false

## 14. SSH management access from the local VPC is enabled by default (true). Uncomment if you want to disable this.
##     Note: Cloud Connector will only be accessible via AWS Session Manager SSM

#mgmt_ssh_enabled                           = false

## 15. By default, a security group is created and assigned to the CC service interface(s).
##     There is an optional rule that permits Cloud Connector to forward direct traffic out
##     on all ports and protocols. (Default: true). Uncomment to restrict to ZIA/ZPA required HTTPS ports only.

#all_ports_egress_enabled                   = false

## 16. By default, this script will apply 1 Security Group per Cloud Connector instance.
##     Uncomment if you want to use the same Security Group for ALL Cloud Connectors (Default: false)

#reuse_security_group                       = true

## 17. By default, this script will apply 1 IAM Role/Instance Profile per Cloud Connector instance.
##     Uncomment if you want to use the same IAM Role/Instance Profile for ALL Cloud Connectors (Default: false)

#reuse_iam                                  = true

## 18. By default, the VPC Endpoint Service created will auto accept any VPC Endpoint registration attempts.
##     Uncomment if you want to require manual acceptance. (Default: false)

#acceptance_required                        = true

## 19. By default, the VPC Endpoint Service will auto accept any registration from any principal in the current AWS Account.
##     Uncomment to override with more specific/restrictive principals.

#allowed_principals                         = ["arn:aws:iam::1234567890:root"]

## 20. By default, terraform will always query the AWS Marketplace for the latest Cloud Connector AMI available.
##     Only uncomment to pin a specific AMI. Not recommended for production.

#ami_id                                     = ["ami-123456789"]

## 21. By default, terraform will configure Cloud Connector with EBS encryption enabled.
##     Uncomment if you want to disable ebs encryption.

#ebs_encryption_enabled                     = false

## 22. By default, EBS encryption uses the AWS default managed/master key.
##     Set as 'alias/<key-alias>' to use an existing customer KMS key.
##     Note: only enforced if ebs_encryption_enabled is set to true.

#byo_kms_key_alias                          = "alias/<customer key alias name>"

## 23. By default, Terraform will create an IAM policy for Cloud Connector instance(s).
##     Uncomment to also create the cc_tags_policy IAM Policy for cloud workload tagging.

#cloud_tags_enabled                         = true

## 24. By default, an outbound rule is configured enabling Zscaler remote support access.
##     Uncomment if you do not want to enable this rule.

#support_access_enabled                     = false
#zssupport_server                           = "199.168.148.101/32"

## 25. By default, this script will create new IAM roles, policy, and Instance Profiles for the Cloud Connector.
##     Uncomment if you want to use existing IAM Instance Profiles. (Default: false)

#byo_iam                                    = true

## 26. Provide your existing Instance Profile resource names. Only uncomment and modify if you set byo_iam to true.
##     Example: byo_iam_instance_profile_id = ["instance-profile-1","instance-profile-2"]

#byo_iam_instance_profile_id               = ["instance-profile-1"]

## 27. By default, this script will create new Security Groups for the Cloud Connector mgmt and service interfaces.
##     Uncomment if you want to use existing SGs. (Default: false)

#byo_security_group                         = true

## 28. Provide your existing Security Group IDs. Only uncomment and modify if you set byo_security_group to true.

#byo_mgmt_security_group_id                = ["mgmt-sg-1","mgmt-sg-2"]
#byo_service_security_group_id             = ["service-sg-1","service-sg-2"]

## 29. By default, this script will create a new VPC Endpoint Service.
##     Uncomment and provide an existing GWLB Endpoint Service name to associate new GWLB Endpoints to an existing service.
##     Example string format: "com.amazonaws.vpce.<region>.<service id>"

#byo_endpoint_service_name                 = "com.amazonaws.vpce.us-east-1.vpce-svc-xxxxxxxxxxxxxxxxx"


#####################################################################################################################
##### BYO (Bring Your Own) Network variables — required for cc_gwlb_tgw brownfield deployment  #####
#####################################################################################################################

## 30. Provide your existing Hub VPC ID.
##     Example: byo_vpc_id = "vpc-0588ce674df615334"

#byo_vpc_id                                = "vpc-0588ce674df615334"

## 31. Provide your existing Cloud Connector subnet IDs (one per AZ, ordered by AZ).
##     Example: byo_cc_subnet_ids = ["subnet-id-az1","subnet-id-az2"]

#byo_cc_subnet_ids                         = ["subnet-id-az1","subnet-id-az2"]

## 32. Provide your existing GWLB Endpoint subnet IDs (one per AZ, ordered by AZ).
##     Example: byo_gwlb_endpoint_subnet_ids = ["subnet-id-az1","subnet-id-az2"]

#byo_gwlb_endpoint_subnet_ids             = ["subnet-id-az1","subnet-id-az2"]

## 33. Provide your existing GWLB Endpoint subnet route table IDs (one per AZ, ordered by AZ).
##     Terraform will inject spoke_vpc_cidrs → TGW routes here for east-west return traffic after CC inspection.
##     Example: byo_gwlb_endpoint_rt_ids = ["rtb-id-az1","rtb-id-az2"]

#byo_gwlb_endpoint_rt_ids                 = ["rtb-id-az1","rtb-id-az2"]

## 34. Provide your existing TGW Attach subnet IDs (one per AZ, ordered by AZ).
##     Example: byo_tgw_attach_subnet_ids = ["subnet-id-az1","subnet-id-az2"]

#byo_tgw_attach_subnet_ids                = ["subnet-id-az1","subnet-id-az2"]

## 35. Provide your existing TGW Attach subnet route table IDs (one per AZ, ordered by AZ).
##     Terraform will inject 0.0.0.0/0 → GWLB Endpoint routes here to steer all TGW-ingress traffic through CC.
##     Example: byo_tgw_attach_rt_ids = ["rtb-id-az1","rtb-id-az2"]

#byo_tgw_attach_rt_ids                    = ["rtb-id-az1","rtb-id-az2"]

## 36. Provide your existing Transit Gateway ID.
##     Example: byo_tgw_id = "tgw-0e5b133f1de67a675"

#byo_tgw_id                               = "tgw-xxxxxxxxxxxxxxxxx"

## 37. List of Spoke VPC CIDR blocks to add as return routes in the GWLB Endpoint subnet route tables pointing to the
##     Transit Gateway. Required for east-west traffic to return correctly after CC inspection.
##     Example: spoke_vpc_cidrs = ["10.1.0.0/16","10.2.0.0/16"]

#spoke_vpc_cidrs                          = ["10.1.0.0/16","10.2.0.0/16"]

## 38. (Optional) Provide an existing public subnet ID in the Hub VPC to deploy an SSH bastion host for CC access.
##     Leave commented out if you do not require a bastion in the Hub VPC (e.g. you have an existing jump host).
##     Example: byo_hub_public_subnet_id = "subnet-0adaaa986f11b20b0"

#byo_hub_public_subnet_id                 = "subnet-id"

## 39. (Optional) CIDR blocks permitted for SSH to the Hub bastion. Only applicable if byo_hub_public_subnet_id is set.
##     Default permits all (0.0.0.0/0). Restrict to your management IP for production security.
##     Example: bastion_nsg_source_prefix = ["x.x.x.x/32"]

#bastion_nsg_source_prefix                = ["0.0.0.0/0"]
