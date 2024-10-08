# Zscaler Custom Deployment Template with Auto Scaling and Gateway Load Balancer (cc_gwlb_asg)

This deployment type is intended for brownfield/production purposes. By default, it will create 1 new VPC with 2 public subnets and 2 Cloud Connector private subnets; 1 IGW; 2 NAT Gateways; Cloud Connector Autoscaling Group + Launch Template spanning all CC subnets routing to the NAT Gateway in their same AZ; generates local key pair .pem file for ssh access; Customizable minimum/maximum number of Cloud Connectors and subnets deployed, ability to use existing resources (VPC, subnets, IGW, NAT Gateways), toggle ZPA/R53 resources; generates local key pair .pem file for ssh access; Gateway Load Balancer with Instance based target group and health checks; VPC Endpoint Service; 2 GWLB Endpoints (1 in each Cloud Connector subnet)

## How to deploy:

### Option 1 (guided):
From the examples directory, run the zsec bash script that walks to all required inputs.
- ./zsec up
- enter "brownfield"
- enter "cc_gwlb_asg"
- follow the remainder of the authentication and configuration input prompts.
- script will detect client operating system and download/run a specific version of terraform in a temporary bin directory
- inputs will be validated and terraform init/apply will automatically exectute.
- verify all resources that will be created/modified and enter "yes" to confirm

### Option 2 (manual):
Modify/populate any required variable input values in cc_gwlb_asg/terraform.tfvars file and save.

From cc_gwlb_asg directory execute:
- terraform init
- terraform apply

## How to destroy:

### Option 1 (guided):
From the examples directory, run the zsec bash script that walks to all required inputs.
- ./zsec destroy

### Option 2 (manual):
From cc_gwlb_asg directory execute:
- terraform destroy

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13.7, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.32.0, <= 5.49.0 |
| <a name="requirement_local"></a> [local](#requirement\_local) | ~> 2.2.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | ~> 3.1.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.3.0 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | ~> 3.4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.32.0, <= 5.49.0 |
| <a name="provider_local"></a> [local](#provider\_local) | ~> 2.2.0 |
| <a name="provider_null"></a> [null](#provider\_null) | ~> 3.1.0 |
| <a name="provider_random"></a> [random](#provider\_random) | ~> 3.3.0 |
| <a name="provider_tls"></a> [tls](#provider\_tls) | ~> 3.4.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_asg_lambda"></a> [asg\_lambda](#module\_asg\_lambda) | ../../modules/terraform-zscc-asg-lambda-aws | n/a |
| <a name="module_cc_asg"></a> [cc\_asg](#module\_cc\_asg) | ../../modules/terraform-zscc-asg-aws | n/a |
| <a name="module_cc_iam"></a> [cc\_iam](#module\_cc\_iam) | ../../modules/terraform-zscc-iam-aws | n/a |
| <a name="module_cc_sg"></a> [cc\_sg](#module\_cc\_sg) | ../../modules/terraform-zscc-sg-aws | n/a |
| <a name="module_gwlb"></a> [gwlb](#module\_gwlb) | ../../modules/terraform-zscc-gwlb-aws | n/a |
| <a name="module_gwlb_endpoint"></a> [gwlb\_endpoint](#module\_gwlb\_endpoint) | ../../modules/terraform-zscc-gwlbendpoint-aws | n/a |
| <a name="module_network"></a> [network](#module\_network) | ../../modules/terraform-zscc-network-aws | n/a |
| <a name="module_route53"></a> [route53](#module\_route53) | ../../modules/terraform-zscc-route53-aws | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_key_pair.deployer](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair) | resource |
| [local_file.private_key](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.testbed](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.user_data_file](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [null_resource.cc_error_checker](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [random_string.suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [tls_private_key.key](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [aws_ami.cloudconnector](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_acceptance_required"></a> [acceptance\_required](#input\_acceptance\_required) | Whether to require manual acceptance of any VPC Endpoint registration attempts to the Endpoint Service or not. Default is false | `bool` | `false` | no |
| <a name="input_all_ports_egress_enabled"></a> [all\_ports\_egress\_enabled](#input\_all\_ports\_egress\_enabled) | Default is true which creates an egress rule permitting the CC service interface to forward direct traffic on all ports and protocols. If false, the rule is not created. Value ignored if not creating a security group | `bool` | `true` | no |
| <a name="input_allowed_principals"></a> [allowed\_principals](#input\_allowed\_principals) | List of AWS Principal ARNs who are allowed access to the GWLB Endpoint Service. E.g. ["arn:aws:iam::1234567890:root"]`. See https://docs.aws.amazon.com/vpc/latest/privatelink/configure-endpoint-service.html#accept-reject-connection-requests` | `list(string)` | `[]` | no |
| <a name="input_ami_id"></a> [ami\_id](#input\_ami\_id) | AMI ID(s) to be used for deploying Cloud Connector appliances. Ideally all VMs should be on the same AMI ID as templates always pull the latest from AWS Marketplace. This variable is provided if a customer desires to override/retain an old ami for existing deployments rather than upgrading and forcing a launch template change. | `list(string)` | <pre>[<br>  ""<br>]</pre> | no |
| <a name="input_asg_enabled"></a> [asg\_enabled](#input\_asg\_enabled) | Determines whether or not to create the cc\_autoscale\_lifecycle\_policy IAM Policy and attach it to the CC IAM Role | `bool` | `true` | no |
| <a name="input_asg_lambda_filename"></a> [asg\_lambda\_filename](#input\_asg\_lambda\_filename) | Name of the lambda zip file without suffix | `string` | `"zscaler_cc_lambda_service"` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | The AWS region. | `string` | `"us-west-2"` | no |
| <a name="input_az_count"></a> [az\_count](#input\_az\_count) | Default number of subnets to create based on availability zone | `number` | `2` | no |
| <a name="input_byo_endpoint_service_name"></a> [byo\_endpoint\_service\_name](#input\_byo\_endpoint\_service\_name) | Exising GWLB Endpoint Service name to associate GWLB Endpoints to. Example string format:  "com.amazonaws.vpce.<region>.<service id>" | `string` | `null` | no |
| <a name="input_byo_iam"></a> [byo\_iam](#input\_byo\_iam) | Bring your own IAM Instance Profile for Cloud Connector | `bool` | `false` | no |
| <a name="input_byo_iam_instance_profile_id"></a> [byo\_iam\_instance\_profile\_id](#input\_byo\_iam\_instance\_profile\_id) | IAM Instance Profile ID for Cloud Connector association | `list(string)` | `null` | no |
| <a name="input_byo_igw"></a> [byo\_igw](#input\_byo\_igw) | Bring your own AWS VPC for Cloud Connector | `bool` | `false` | no |
| <a name="input_byo_igw_id"></a> [byo\_igw\_id](#input\_byo\_igw\_id) | User provided existing AWS Internet Gateway ID | `string` | `null` | no |
| <a name="input_byo_kms_key_alias"></a> [byo\_kms\_key\_alias](#input\_byo\_kms\_key\_alias) | Requires var.ebs\_encryption\_enabled to be true. Set to null by default which is the AWS default managed/master key. Set as 'alias/<key-alias>' to use a custom KMS key | `string` | `null` | no |
| <a name="input_byo_mgmt_security_group_id"></a> [byo\_mgmt\_security\_group\_id](#input\_byo\_mgmt\_security\_group\_id) | Management Security Group ID for Cloud Connector association | `list(string)` | `null` | no |
| <a name="input_byo_ngw"></a> [byo\_ngw](#input\_byo\_ngw) | Bring your own AWS NAT Gateway(s) Cloud Connector | `bool` | `false` | no |
| <a name="input_byo_ngw_ids"></a> [byo\_ngw\_ids](#input\_byo\_ngw\_ids) | User provided existing AWS NAT Gateway IDs | `list(string)` | `null` | no |
| <a name="input_byo_security_group"></a> [byo\_security\_group](#input\_byo\_security\_group) | Bring your own Security Group for Cloud Connector | `bool` | `false` | no |
| <a name="input_byo_service_security_group_id"></a> [byo\_service\_security\_group\_id](#input\_byo\_service\_security\_group\_id) | Service Security Group ID for Cloud Connector association | `list(string)` | `null` | no |
| <a name="input_byo_sns_topic"></a> [byo\_sns\_topic](#input\_byo\_sns\_topic) | Determine whether or not to create an AWS SNS topic and topic subscription for email alerts. Setting this variable to true implies you should also set variable sns\_enabled to true | `bool` | `false` | no |
| <a name="input_byo_sns_topic_name"></a> [byo\_sns\_topic\_name](#input\_byo\_sns\_topic\_name) | Existing SNS Topic friendly name to be used for autoscaling group notifications | `string` | `""` | no |
| <a name="input_byo_subnet_ids"></a> [byo\_subnet\_ids](#input\_byo\_subnet\_ids) | User provided existing AWS Subnet IDs | `list(string)` | `null` | no |
| <a name="input_byo_subnets"></a> [byo\_subnets](#input\_byo\_subnets) | Bring your own AWS Subnets for Cloud Connector | `bool` | `false` | no |
| <a name="input_byo_vpc"></a> [byo\_vpc](#input\_byo\_vpc) | Bring your own AWS VPC for Cloud Connector | `bool` | `false` | no |
| <a name="input_byo_vpc_id"></a> [byo\_vpc\_id](#input\_byo\_vpc\_id) | User provided existing AWS VPC ID | `string` | `null` | no |
| <a name="input_cc_instance_size"></a> [cc\_instance\_size](#input\_cc\_instance\_size) | Cloud Connector Instance size. Determined by and needs to match the Cloud Connector Portal provisioning template configuration | `string` | `"small"` | no |
| <a name="input_cc_route_table_enabled"></a> [cc\_route\_table\_enabled](#input\_cc\_route\_table\_enabled) | For brownfield environments where VPC subnets already exist, set to false to not create a new route table to associate to Cloud Connector subnet(s). Default is true which means module will try to create new route tables | `bool` | `true` | no |
| <a name="input_cc_subnets"></a> [cc\_subnets](#input\_cc\_subnets) | Cloud Connector Subnets to create in VPC. This is only required if you want to override the default subnets that this code creates via vpc\_cidr variable. | `list(string)` | `null` | no |
| <a name="input_cc_vm_prov_url"></a> [cc\_vm\_prov\_url](#input\_cc\_vm\_prov\_url) | Zscaler Cloud Connector Provisioning URL | `string` | n/a | yes |
| <a name="input_ccvm_instance_type"></a> [ccvm\_instance\_type](#input\_ccvm\_instance\_type) | Cloud Connector Instance Type | `string` | `"m6i.large"` | no |
| <a name="input_cloud_tags_enabled"></a> [cloud\_tags\_enabled](#input\_cloud\_tags\_enabled) | Determines whether or not to create the cc\_tags\_policy IAM Policy and attach it to the CC IAM Role | `bool` | `false` | no |
| <a name="input_cross_zone_lb_enabled"></a> [cross\_zone\_lb\_enabled](#input\_cross\_zone\_lb\_enabled) | Determines whether GWLB cross zone load balancing should be enabled or not | `bool` | `false` | no |
| <a name="input_deregistration_delay"></a> [deregistration\_delay](#input\_deregistration\_delay) | Amount time for Elastic Load Balancing to wait before changing the state of a deregistering target from draining to unused. The range is 0-3600 seconds. | `number` | `0` | no |
| <a name="input_domain_names"></a> [domain\_names](#input\_domain\_names) | Domain names fqdn/wildcard to have Route 53 redirect DNS requests to Cloud Connector for ZPA. Refer to terraform.tfvars ZPA/Route 53 specific variables | `map(any)` | `{}` | no |
| <a name="input_ebs_encryption_enabled"></a> [ebs\_encryption\_enabled](#input\_ebs\_encryption\_enabled) | true/false whether to enable EBS encryption on the root volume. Default is true | `bool` | `true` | no |
| <a name="input_ebs_volume_type"></a> [ebs\_volume\_type](#input\_ebs\_volume\_type) | (Optional) Type of volume. Valid values include standard, gp2, gp3, io1, io2, sc1, or st1. Defaults to gp3 | `string` | `"gp3"` | no |
| <a name="input_flow_stickiness"></a> [flow\_stickiness](#input\_flow\_stickiness) | Options are (Default) 5-tuple (src ip/src port/dest ip/dest port/protocol), 3-tuple (src ip/dest ip/protocol), or 2-tuple (src ip/dest ip) | `string` | `"5-tuple"` | no |
| <a name="input_gwlb_enabled"></a> [gwlb\_enabled](#input\_gwlb\_enabled) | Default is true. Workload/Route 53 subnet route tables will point to vpc\_endpoint\_id via var.gwlb\_endpoint\_ids input. If false, these Route Tables will point to network\_interface\_id via var.cc\_service\_enis | `bool` | `true` | no |
| <a name="input_health_check_grace_period"></a> [health\_check\_grace\_period](#input\_health\_check\_grace\_period) | The health check grace period specifies the minimum amount of time (in seconds) to keep a new instance in service before terminating it if it's found to be unhealthy. | `number` | `900` | no |
| <a name="input_health_check_interval"></a> [health\_check\_interval](#input\_health\_check\_interval) | Interval for GWLB target group health check probing, in seconds, of Cloud Connector targets. Minimum 5 and maximum 300 seconds | `number` | `10` | no |
| <a name="input_healthy_threshold"></a> [healthy\_threshold](#input\_healthy\_threshold) | The number of successful health checks required before an unhealthy target becomes healthy. Minimum 2 and maximum 10 | `number` | `2` | no |
| <a name="input_http_probe_port"></a> [http\_probe\_port](#input\_http\_probe\_port) | Port number for Cloud Connector cloud init to enable listener port for HTTP probe from GWLB Target Group | `number` | `50000` | no |
| <a name="input_instance_warmup"></a> [instance\_warmup](#input\_instance\_warmup) | Amount of time, in seconds, until a newly launched instance can contribute to the Amazon CloudWatch metrics. This delay lets an instance finish initializing before Amazon EC2 Auto Scaling aggregates instance metrics, resulting in more reliable usage data. Set this value equal to the amount of time that it takes for resource consumption to become stable after an instance reaches the InService state | `number` | `0` | no |
| <a name="input_launch_template_version"></a> [launch\_template\_version](#input\_launch\_template\_version) | Launch template version. Can be version number, `$Latest` or `$Default` | `string` | `"$Latest"` | no |
| <a name="input_lifecyclehook_instance_launch_wait_time"></a> [lifecyclehook\_instance\_launch\_wait\_time](#input\_lifecyclehook\_instance\_launch\_wait\_time) | The maximum amount of time to wait in pending:wait state on instance launch in warmpool | `number` | `1800` | no |
| <a name="input_lifecyclehook_instance_terminate_wait_time"></a> [lifecyclehook\_instance\_terminate\_wait\_time](#input\_lifecyclehook\_instance\_terminate\_wait\_time) | The maximum amount of time to wait in terminating:wait state on instance termination | `number` | `900` | no |
| <a name="input_max_size"></a> [max\_size](#input\_max\_size) | Maxinum number of Cloud Connectors to maintain in Autoscaling group | `number` | `4` | no |
| <a name="input_mgmt_ssh_enabled"></a> [mgmt\_ssh\_enabled](#input\_mgmt\_ssh\_enabled) | Default is true which creates an ingress rule permitting SSH traffic from the local VPC to the CC management interface. If false, the rule is not created. Value ignored if not creating a security group | `bool` | `true` | no |
| <a name="input_min_size"></a> [min\_size](#input\_min\_size) | Mininum number of Cloud Connectors to maintain in Autoscaling group | `number` | `2` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | The name prefix for all your resources | `string` | `"zscc"` | no |
| <a name="input_owner_tag"></a> [owner\_tag](#input\_owner\_tag) | populate custom owner tag attribute | `string` | `"zscc-admin"` | no |
| <a name="input_protect_from_scale_in"></a> [protect\_from\_scale\_in](#input\_protect\_from\_scale\_in) | Whether newly launched instances are automatically protected from termination by Amazon EC2 Auto Scaling when scaling in. For more information about preventing instances from terminating on scale in, see Using instance scale-in protection in the Amazon EC2 Auto Scaling User Guide | `bool` | `false` | no |
| <a name="input_public_subnets"></a> [public\_subnets](#input\_public\_subnets) | Public/NAT GW Subnets to create in VPC. This is only required if you want to override the default subnets that this code creates via vpc\_cidr variable. | `list(string)` | `null` | no |
| <a name="input_rebalance_enabled"></a> [rebalance\_enabled](#input\_rebalance\_enabled) | Indicates how the GWLB handles existing flows when a target is deregistered or marked unhealthy. true means rebalance. false means no\_rebalance. Default: true | `bool` | `true` | no |
| <a name="input_reuse_on_scale_in"></a> [reuse\_on\_scale\_in](#input\_reuse\_on\_scale\_in) | Specifies whether instances in the Auto Scaling group can be returned to the warm pool on scale in. Default recommendation is true | `bool` | `true` | no |
| <a name="input_route53_subnets"></a> [route53\_subnets](#input\_route53\_subnets) | Route 53 Outbound Endpoint Subnets to create in VPC. This is only required if you want to override the default subnets that this code creates via vpc\_cidr variable. | `list(string)` | `null` | no |
| <a name="input_secret_name"></a> [secret\_name](#input\_secret\_name) | AWS Secrets Manager Secret Name for Cloud Connector provisioning | `string` | n/a | yes |
| <a name="input_sns_email_list"></a> [sns\_email\_list](#input\_sns\_email\_list) | List of email addresses to input for sns topic subscriptions for autoscaling group notifications. Required if sns\_enabled variable is true and byo\_sns\_topic false | `list(string)` | <pre>[<br>  ""<br>]</pre> | no |
| <a name="input_sns_enabled"></a> [sns\_enabled](#input\_sns\_enabled) | Determine whether or not to create autoscaling group notifications. Default is false. If setting this value to true, terraform will also create a new sns topic and topic subscription | `bool` | `false` | no |
| <a name="input_support_access_enabled"></a> [support\_access\_enabled](#input\_support\_access\_enabled) | If Network Security Group is being configured, enable a specific outbound rule for Cloud Connector to be able to establish connectivity for Zscaler support access. Default is true | `bool` | `true` | no |
| <a name="input_target_address"></a> [target\_address](#input\_target\_address) | Route 53 DNS queries will be forwarded to these Zscaler Global VIP addresses | `list(string)` | <pre>[<br>  "185.46.212.88",<br>  "185.46.212.89"<br>]</pre> | no |
| <a name="input_target_cpu_util_value"></a> [target\_cpu\_util\_value](#input\_target\_cpu\_util\_value) | Target value number for autoscaling policy CPU utilization target tracking. ie: trigger a scale in/out to keep average CPU Utliization percentage across all instances at/under this number | `number` | `80` | no |
| <a name="input_tls_key_algorithm"></a> [tls\_key\_algorithm](#input\_tls\_key\_algorithm) | algorithm for tls\_private\_key resource | `string` | `"RSA"` | no |
| <a name="input_unhealthy_threshold"></a> [unhealthy\_threshold](#input\_unhealthy\_threshold) | The number of unsuccessful health checks required before an healthy target becomes unhealthy. Minimum 2 and maximum 10 | `number` | `3` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | VPC IP CIDR Range. All subnet resources that might get created (public, workload, cloud connector) are derived from this /16 CIDR. If you require creating a VPC smaller than /16, you may need to explicitly define all other subnets via public\_subnets, workload\_subnets, cc\_subnets, and route53\_subnets variables | `string` | `"10.1.0.0/16"` | no |
| <a name="input_warm_pool_enabled"></a> [warm\_pool\_enabled](#input\_warm\_pool\_enabled) | If set to true, add a warm pool to the specified Auto Scaling group. See [warm\_pool](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group#warm_pool). | `bool` | `false` | no |
| <a name="input_warm_pool_max_group_prepared_capacity"></a> [warm\_pool\_max\_group\_prepared\_capacity](#input\_warm\_pool\_max\_group\_prepared\_capacity) | Specifies the total maximum number of instances that are allowed to be in the warm pool or in any state except Terminated for the Auto Scaling group. Ignored when 'warm\_pool\_enabled' is false | `number` | `null` | no |
| <a name="input_warm_pool_min_size"></a> [warm\_pool\_min\_size](#input\_warm\_pool\_min\_size) | Specifies the minimum number of instances to maintain in the warm pool. This helps you to ensure that there is always a certain number of warmed instances available to handle traffic spikes. Ignored when 'warm\_pool\_enabled' is false | `number` | `0` | no |
| <a name="input_warm_pool_state"></a> [warm\_pool\_state](#input\_warm\_pool\_state) | Sets the instance state to transition to after the lifecycle hooks finish. Valid values are: Stopped (default) or Running. Ignored when 'warm\_pool\_enabled' is false | `string` | `"Stopped"` | no |
| <a name="input_workloads_enabled"></a> [workloads\_enabled](#input\_workloads\_enabled) | Configure Workload Subnets, Route Tables, and associations if set to true | `bool` | `false` | no |
| <a name="input_zonal_asg_enabled"></a> [zonal\_asg\_enabled](#input\_zonal\_asg\_enabled) | The number of Auto Scaling Groups to create. By default, Terraform will create a single Auto Scaling Group containing multiple subnets/availability zones. Set to true if you would rather create one Auto Scaling Group per subnet/availability zone (var.az\_count) | `bool` | `false` | no |
| <a name="input_zpa_enabled"></a> [zpa\_enabled](#input\_zpa\_enabled) | Configure Route 53 Subnets, Route Tables, and Resolvers for ZPA DNS redirection | `bool` | `false` | no |
| <a name="input_zssupport_server"></a> [zssupport\_server](#input\_zssupport\_server) | destination IP address of Zscaler Support access server. IP resolution of remotesupport.<zscaler\_customer\_cloud>.net | `string` | `"199.168.148.101/32"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_testbedconfig"></a> [testbedconfig](#output\_testbedconfig) | AWS Testbed results |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
