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
#ccvm_instance_type                         = "t3a.medium"
#ccvm_instance_type                         = "m5n.large"
#ccvm_instance_type                         = "c5a.large"
#ccvm_instance_type                         = "m6i.large"
#ccvm_instance_type                         = "c6i.large"
#ccvm_instance_type                         = "m5n.4xlarge"
#ccvm_instance_type                         = "c5.4xlarge"
#ccvm_instance_type                         = "m6i.4xlarge"
#ccvm_instance_type                         = "c6i.4xlarge"

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

## 8. The number of Cloud Connector appliances to create. (Default: 1)
##    For GWLB deployments cc_count can be set between 1 and 20.

#cc_count                                   = 1

## 9. AWS Availability Zone count selection. (Default: 1)
##    This determines how many AZ subnets are created for Hub and Spoke VPCs.

#az_count                                   = 1

## 10. By default, EC2 Bastion/Workload hosts are permitted SSH access from any IP address.
##     Uncomment and set to restrict SSH access from specific CIDR(s).

#bastion_nsg_source_prefix                  = ["1.2.3.4/32"]

## 11. Number of workload VMs to create per spoke VPC. (Default: 1)

#workload_count                             = 1


#####################################################################################################################
##### TGW Hub-Spoke specific variables  #####
#####################################################################################################################

## 12. Hub VPC CIDR. All hub subnets are derived from this range. (Default: 10.0.0.0/16)
##     Derived subnets (all /24):
##       public_subnet        : .101.0  (NAT GW)
##       tgw_attach_subnet    : .1.0    (TGW ENIs)
##       gwlb_endpoint_subnet : .2.0    (GWLB Endpoint VPCE)
##       cc_subnet            : .200.0  (Cloud Connector VMs)

#hub_vpc_cidr                               = "10.0.0.0/16"

## 13. Spoke 1 VPC CIDR. Workload VMs are deployed in this range. (Default: 10.1.0.0/16)

#spoke_1_vpc_cidr                           = "10.1.0.0/16"

## 14. Spoke 2 VPC CIDR. Workload VMs are deployed in this range. (Default: 10.2.0.0/16)

#spoke_2_vpc_cidr                           = "10.2.0.0/16"

## 15. Transit Gateway name prefix. (Default: zscc-tgw)

#tgw_name                                   = "zscc-tgw"

## 16. Hard coded private IP for spoke 1 workload VM. (Default: 10.1.1.50)

#workload_private_ip                        = "10.1.1.50"

## 17. Hard coded private IP for spoke 2 workload VM. (Default: 10.2.1.50)

#workload_2_private_ip                      = "10.2.1.50"


#####################################################################################################################
##### GWLB variables  #####
#####################################################################################################################

## 18. Enable or disable GWLB cross-zone load balancing. (Default: false)

#cross_zone_lb_enabled                      = false

## 19. GWLB flow stickiness. Options: 2-tuple, 3-tuple, 5-tuple. (Default: 5-tuple)

#flow_stickiness                            = "5-tuple"

## 20. Enable GWLB target failover/rebalance for existing flows on deregistration. (Default: true)

#rebalance_enabled                          = true

## 21. GWLB health check interval in seconds. (Default: 10)

#health_check_interval                      = 10

## 22. Number of successful health checks before target is healthy. (Default: 2)

#healthy_threshold                          = 2

## 23. Number of failed health checks before target is unhealthy. (Default: 3)

#unhealthy_threshold                        = 3


#####################################################################################################################
##### Encryption variables  #####
#####################################################################################################################

## 24. Enable EBS encryption. (Default: true)

#ebs_encryption_enabled                     = true

## 25. Custom KMS key alias for EBS encryption. Leave null to use AWS default managed key.

#byo_kms_key_alias                          = "alias/my-key"


#####################################################################################################################
##### Optional/Advanced variables  #####
#####################################################################################################################

## 26. Reuse a single security group for all CC instances. (Default: false = 1:1 SG per CC)

#reuse_security_group                       = false

## 27. Reuse a single IAM role for all CC instances. (Default: false = 1:1 IAM per CC)

#reuse_iam                                  = false

## 28. Override AMI ID(s). Leave default "" to use latest from AWS Marketplace.

#ami_id                                     = [""]

## 29. Enable IAM permissions for cloud workload tagging. (Default: false)

#cloud_tags_enabled                         = false
