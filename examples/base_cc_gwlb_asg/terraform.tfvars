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

## 7. The number of Cloud Connector Subnets to create in sequential availability zones. Available input range 1-3 (Default: 2)
##    **** NOTE - This value will be ignored if byo_vpc / byo_subnets

#az_count                                   = 2

## 8. The number of Auto Scaling Groups to create. By default, Terraform will create one Auto Scaling Group per subnet/availability zone. 
##    Uncomment and set to false if you would rather create a single Auto Scaling Group containing multiple subnets/availability zones

#zonal_asg_enabled                          = false

## 9. The minimum number of Cloud Connectors to maintain in an Autoscaling group. (Default: 2)
##    Recommendation is to maintain HA/Zonal resliency so for example if az_count = 2 and cross_zone_lb_enabled is false the minimum number of CCs you would want for a
##    production deployment would be 4

#min_size                                   = 2

## 10. The maximum number of Cloud Connectors to maintain in an Autoscaling group. (Default: 4)
##    Value must be a number between 1 and 10

#max_size                                   = 4

## 11. The amount of time until EC2 Auto Scaling performs the first health check on new instances after they are put into service. 
##     With lifecycle hooks it is immediate. Otheriwse Default is 15 minutes. (Default: 900 seconds/15 minutes)

#health_check_grace_period                  = 0

## 12. Amount of time, in seconds, until a newly launched instance can contribute to the Amazon CloudWatch metrics. 
##     This delay lets an instance finish initializing before Amazon EC2 Auto Scaling aggregates instance metrics, resulting in more reliable usage data.
##     Default: 0 seconds

#instance_warmup                            = 0

## 13. Whether newly launched instances are automatically protected from termination by Amazon EC2 Auto Scaling when scaling in. 
##     Uncomment to disable. (Default: true)

#protect_from_scale_in                      = false

## 14. IPv4 CIDR configured with VPC creation. Workload, Public, and Cloud Connector Subnets will be created based off this prefix
##    /24 subnets are created assuming this cidr is a /16. You may need to edit cidr_block values for subnet creations if
##    desired for smaller or larger subnets. (Default: "10.1.0.0/16")

#vpc_cidr                                   = "10.1.0.0/16"

## 15. Number of Workload VMs to be provisioned in the workload subnet. Only limitation is available IP space
##    in subnet configuration. Only applicable for "base" deployment types. Default workload subnet is /24 so 250 max

#workload_count                             = 2

## 16. Tag attribute "Owner" assigned to all resoure creation. (Default: "zscc-admin")

#owner_tag                                  = "username@company.com"

## 17. By default, terraform will always query the AWS Marketplace for the latest Cloud Connector AMI available.
##     This variable is provided if a customer desires to override/retain an old ami for existing deployments rather than upgrading and forcing a launch template change."

##     Note: Customers should NOT be hard coding AMI IDs as Zscaler recommendation is to always be deploying/running the latest version.
##           Leave this variable commented out unless you are absolutely certain why/that you need to set it and only temporarily.
##
##           This variable is supplied as a list, but only a single/the first AMI in the list is used by the launch template.

#ami_id                                     = ["ami-123456789"]

## 18. By default, GWLB deployments are configured as zonal. Uncomment if you want to enable cross-zone load balancing
##     functionality. Only applicable for gwlb deployment types. (Default: false)

#cross_zone_lb_enabled                      = true

## 19. Gateway loadbalancing hashing algorithm. Default is 5-tuple (None).
##     Additional options include: 2-tuple (source_ip_dest_ip) and 3-tuple (source_ip_dest_ip_proto)
##     Uncomment below the configuration you want to use.

#flow_stickiness                            = "2-tuple"
#flow_stickiness                            = "3-tuple"
#flow_stickiness                            = "5-tuple"

## 20. Indicates how the GWLB handles existing flows when a target is deregistered or marked unhealthy. 
##     true means rebalance after deregistration. false means no_rebalance. (Default: true)
##     Uncomment to turn this feature off (not recommended)

#rebalance_enabled                          = false

## 21. If set to true, add a warm pool to the specified Auto Scaling group. See [warm_pool](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group#warm_pool).
##     Uncomment to enable. (Default: false)

#warm_pool_enabled                          = true

## 22. Sets the instance state to transition to after the lifecycle hooks finish. Valid values are: Stopped (default) or Running. Ignored when 'warm_pool_enabled' is false
##     Uncomment the desired value

#warm_pool_state                            = "Stopped"
#warm_pool_state                            = "Running"

## 23. Specifies the minimum number of instances to maintain in the warm pool. This helps you to ensure that there is always a certain number of warmed instances available to handle traffic spikes. Ignored when 'warm_pool_enabled' is false
##     Uncomment and specify a desired minimum number of Cloud Connectors to maintain deployed in a warm pool

#warm_pool_min_size                         = 0

## 24. Specifies the total maximum number of instances that are allowed to be in the warm pool or in any state except Terminated for the Auto Scaling group. Ignored when 'warm_pool_enabled' is false
##     Uncomment and specify a desired maximum number of Cloud Connectors to maintain deployed in a warm pool. Default is null which means use whatever maximum is set at the ASG.

#warm_pool_max_group_prepared_capacity      = null

## 25. Specifies whether instances in the Auto Scaling group can be returned to the warm pool on scale in
##     Uncomment to disable. (Default: true)

#reuse_on_scale_in                          = false

## 26. Target value number for autoscaling policy CPU utilization target tracking. ie: trigger a scale in/out to keep average CPU Utliization percentage across all instances at/under this number
##     (Default: 80%)

#target_cpu_util_value                      = 80

## 27. Determine whether or not to create autoscaling group notifications. Default is false. If setting this value to true, terraform will also create a new sns topic and topic subscription in the same AWS account"

#sns_enabled                                = true

## 28. List of email addresses to input for sns topic subscriptions for autoscaling group notifications. Required if sns_enabled variable is true and byo_sns_topic false

#sns_email_list                             = ["john@corp.com","bob@corp.com"]

## 29. Determine whether or not to create an AWS SNS topic and topic subscription for email alerts. Setting this variable to true implies you should also set variable sns_enabled to true
##     Default: false

#byo_sns_topic                              = true

## 30. Existing SNS Topic friendly name to be used for autoscaling group notifications assignment

#byo_sns_topic_name                         = "topic-name"

## 31. SSH management access from the local VPC is enabled by default (true). Uncomment if you
##     want to disable this.
##     Note: Cloud Connector will only be accessible via AWS Session Manager SSM

#mgmt_ssh_enabled                           = false

## 32. By default, a security group is created and assigned to the CC service interface(s).
##     There is an optional rule that permits Cloud Connector to forward direct traffic out
##     on all ports and protocols. (Default: true). Uncomment if you want to restrict
##     traffic to only the ZIA/ZPA required HTTPS TCP/UDP ports.

#all_ports_egress_enabled                   = false

## 33. By default, terraform will configure Cloud Connector with EBS encryption enabled.
##     Uncomment if you want to disable ebs encryption.

#ebs_encryption_enabled                     = false

## 34. By default, EBS encryptions is set to null which uses the AWS default managed/master key.
##     Set as 'alias/<key-alias>' to use an existing customer KMS key"

##     Note: this variable is only enforced if ebs_encryption_enabled is set to true

#byo_kms_key_alias                          = "alias/<customer key alias name>"
