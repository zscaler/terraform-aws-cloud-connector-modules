# Zscaler "cc_gwlb_asg" deployment type

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
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 4.7.0 |
| <a name="requirement_local"></a> [local](#requirement\_local) | ~> 2.2.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | ~> 3.1.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.3.0 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | ~> 3.4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 4.7.0 |
| <a name="provider_local"></a> [local](#provider\_local) | ~> 2.2.0 |
| <a name="provider_null"></a> [null](#provider\_null) | ~> 3.1.0 |
| <a name="provider_random"></a> [random](#provider\_random) | ~> 3.3.0 |
| <a name="provider_tls"></a> [tls](#provider\_tls) | ~> 3.4.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
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

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_acceptance_required"></a> [acceptance\_required](#input\_acceptance\_required) | Whether to require manual acceptance of any VPC Endpoint registration attempts to the Endpoint Service or not. Default is false | `bool` | `false` | no |
| <a name="input_allowed_principals"></a> [allowed\_principals](#input\_allowed\_principals) | List of AWS Principal ARNs who are allowed access to the GWLB Endpoint Service. E.g. ["arn:aws:iam::1234567890:root"]`. See https://docs.aws.amazon.com/vpc/latest/privatelink/configure-endpoint-service.html#accept-reject-connection-requests` | `list(string)` | `[]` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | The AWS region. | `string` | `"us-west-2"` | no |
| <a name="input_az_count"></a> [az\_count](#input\_az\_count) | Default number of subnets to create based on availability zone | `number` | `2` | no |
| <a name="input_byo_iam"></a> [byo\_iam](#input\_byo\_iam) | Bring your own IAM Instance Profile for Cloud Connector | `bool` | `false` | no |
| <a name="input_byo_iam_instance_profile_id"></a> [byo\_iam\_instance\_profile\_id](#input\_byo\_iam\_instance\_profile\_id) | IAM Instance Profile ID for Cloud Connector association | `list(string)` | `null` | no |
| <a name="input_byo_igw"></a> [byo\_igw](#input\_byo\_igw) | Bring your own AWS VPC for Cloud Connector | `bool` | `false` | no |
| <a name="input_byo_igw_id"></a> [byo\_igw\_id](#input\_byo\_igw\_id) | User provided existing AWS Internet Gateway ID | `string` | `null` | no |
| <a name="input_byo_mgmt_security_group_id"></a> [byo\_mgmt\_security\_group\_id](#input\_byo\_mgmt\_security\_group\_id) | Management Security Group ID for Cloud Connector association | `list(string)` | `null` | no |
| <a name="input_byo_ngw"></a> [byo\_ngw](#input\_byo\_ngw) | Bring your own AWS NAT Gateway(s) Cloud Connector | `bool` | `false` | no |
| <a name="input_byo_ngw_ids"></a> [byo\_ngw\_ids](#input\_byo\_ngw\_ids) | User provided existing AWS NAT Gateway IDs | `list(string)` | `null` | no |
| <a name="input_byo_security_group"></a> [byo\_security\_group](#input\_byo\_security\_group) | Bring your own Security Group for Cloud Connector | `bool` | `false` | no |
| <a name="input_byo_service_security_group_id"></a> [byo\_service\_security\_group\_id](#input\_byo\_service\_security\_group\_id) | Service Security Group ID for Cloud Connector association | `list(string)` | `null` | no |
| <a name="input_byo_subnet_ids"></a> [byo\_subnet\_ids](#input\_byo\_subnet\_ids) | User provided existing AWS Subnet IDs | `list(string)` | `null` | no |
| <a name="input_byo_subnets"></a> [byo\_subnets](#input\_byo\_subnets) | Bring your own AWS Subnets for Cloud Connector | `bool` | `false` | no |
| <a name="input_byo_vpc"></a> [byo\_vpc](#input\_byo\_vpc) | Bring your own AWS VPC for Cloud Connector | `bool` | `false` | no |
| <a name="input_byo_vpc_id"></a> [byo\_vpc\_id](#input\_byo\_vpc\_id) | User provided existing AWS VPC ID | `string` | `null` | no |
| <a name="input_cc_callhome_enabled"></a> [cc\_callhome\_enabled](#input\_cc\_callhome\_enabled) | determine whether or not to create the cc-callhome-policy IAM Policy and attach it to the CC IAM Role | `bool` | `true` | no |
| <a name="input_cc_instance_size"></a> [cc\_instance\_size](#input\_cc\_instance\_size) | Cloud Connector Instance size. Determined by and needs to match  the Cloud Connector Portal provisioning template configuration | `string` | `"small"` | no |
| <a name="input_cc_subnets"></a> [cc\_subnets](#input\_cc\_subnets) | Cloud Connector Subnets to create in VPC. This is only required if you want to override the default subnets that this code creates via vpc\_cidr variable. | `list(string)` | `null` | no |
| <a name="input_cc_vm_prov_url"></a> [cc\_vm\_prov\_url](#input\_cc\_vm\_prov\_url) | Zscaler Cloud Connector Provisioning URL | `string` | n/a | yes |
| <a name="input_ccvm_instance_type"></a> [ccvm\_instance\_type](#input\_ccvm\_instance\_type) | Cloud Connector Instance Type | `string` | `"m5.large"` | no |
| <a name="input_cross_zone_lb_enabled"></a> [cross\_zone\_lb\_enabled](#input\_cross\_zone\_lb\_enabled) | Determines whether GWLB cross zone load balancing should be enabled or not | `bool` | `false` | no |
| <a name="input_domain_names"></a> [domain\_names](#input\_domain\_names) | Domain names fqdn/wildcard to have Route 53 redirect DNS requests to Cloud Connector for ZPA. Refer to terraform.tfvars step 10 | `map(map(string))` | <pre>{<br>  "appseg01": {<br>    "domain_name": "example.com"<br>  }<br>}</pre> | no |
| <a name="input_gwlb_enabled"></a> [gwlb\_enabled](#input\_gwlb\_enabled) | Default is true. Workload/Route 53 subnet route tables will point to vpc\_endpoint\_id via var.gwlb\_endpoint\_ids input. If false, these Route Tables will point to network\_interface\_id via var.cc\_service\_enis | `bool` | `true` | no |
| <a name="input_health_check_grace_period"></a> [health\_check\_grace\_period](#input\_health\_check\_grace\_period) | The amount of time until EC2 Auto Scaling performs the first health check on new instances after they are put into service. Default is 15 minutes | `number` | `900` | no |
| <a name="input_health_check_interval"></a> [health\_check\_interval](#input\_health\_check\_interval) | Interval for GWLB target group health check probing, in seconds, of Cloud Connector targets. Minimum 5 and maximum 300 seconds | `number` | `10` | no |
| <a name="input_healthy_threshold"></a> [healthy\_threshold](#input\_healthy\_threshold) | The number of successful health checks required before an unhealthy target becomes healthy. Minimum 2 and maximum 10 | `number` | `3` | no |
| <a name="input_http_probe_port"></a> [http\_probe\_port](#input\_http\_probe\_port) | Port number for Cloud Connector cloud init to enable listener port for HTTP probe from GWLB Target Group | `number` | `50000` | no |
| <a name="input_launch_template_version"></a> [launch\_template\_version](#input\_launch\_template\_version) | Launch template version. Can be version number, `$Latest` or `$Default` | `string` | `"$Latest"` | no |
| <a name="input_max_size"></a> [max\_size](#input\_max\_size) | Maxinum number of Cloud Connectors to maintain in Autoscaling group | `number` | `4` | no |
| <a name="input_min_size"></a> [min\_size](#input\_min\_size) | Mininum number of Cloud Connectors to maintain in Autoscaling group | `number` | `2` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | The name prefix for all your resources | `string` | `"zsdemo"` | no |
| <a name="input_owner_tag"></a> [owner\_tag](#input\_owner\_tag) | populate custom owner tag attribute | `string` | `"zscc-admin"` | no |
| <a name="input_public_subnets"></a> [public\_subnets](#input\_public\_subnets) | Public/NAT GW Subnets to create in VPC. This is only required if you want to override the default subnets that this code creates via vpc\_cidr variable. | `list(string)` | `null` | no |
| <a name="input_reuse_on_scale_in"></a> [reuse\_on\_scale\_in](#input\_reuse\_on\_scale\_in) | Specifies whether instances in the Auto Scaling group can be returned to the warm pool on scale in. | `bool` | `"false"` | no |
| <a name="input_route53_subnets"></a> [route53\_subnets](#input\_route53\_subnets) | Route 53 Outbound Endpoint Subnets to create in VPC. This is only required if you want to override the default subnets that this code creates via vpc\_cidr variable. | `list(string)` | `null` | no |
| <a name="input_secret_name"></a> [secret\_name](#input\_secret\_name) | AWS Secrets Manager Secret Name for Cloud Connector provisioning | `string` | n/a | yes |
| <a name="input_target_address"></a> [target\_address](#input\_target\_address) | Route 53 DNS queries will be forwarded to these Zscaler Global VIP addresses | `list(string)` | <pre>[<br>  "185.46.212.88",<br>  "185.46.212.89"<br>]</pre> | no |
| <a name="input_target_cpu_util_value"></a> [target\_cpu\_util\_value](#input\_target\_cpu\_util\_value) | Target value number for autoscaling policy CPU utilization target tracking. ie: trigger a scale in/out to keep average CPU Utliization percentage across all instances at/under this number | `number` | `70` | no |
| <a name="input_target_tracking_metric"></a> [target\_tracking\_metric](#input\_target\_tracking\_metric) | The AWS ASG pre-defined target tracking metric type. Cloud Connector recommends ASGAverageCPUUtilization | `string` | `"ASGAverageCPUUtilization"` | no |
| <a name="input_tls_key_algorithm"></a> [tls\_key\_algorithm](#input\_tls\_key\_algorithm) | algorithm for tls\_private\_key resource | `string` | `"RSA"` | no |
| <a name="input_unhealthy_threshold"></a> [unhealthy\_threshold](#input\_unhealthy\_threshold) | The number of unsuccessful health checks required before an healthy target becomes unhealthy. Minimum 2 and maximum 10 | `number` | `3` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | VPC IP CIDR Range. All subnet resources that might get created (public, workload, cloud connector) are derived from this /16 CIDR. If you require creating a VPC smaller than /16, you may need to explicitly define all other subnets via public\_subnets, workload\_subnets, cc\_subnets, and route53\_subnets variables | `string` | `"10.1.0.0/16"` | no |
| <a name="input_warm_pool_enabled"></a> [warm\_pool\_enabled](#input\_warm\_pool\_enabled) | If set to true, add a warm pool to the specified Auto Scaling group. See [warm\_pool](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group#warm_pool). | `bool` | `"false"` | no |
| <a name="input_warm_pool_max_group_prepared_capacity"></a> [warm\_pool\_max\_group\_prepared\_capacity](#input\_warm\_pool\_max\_group\_prepared\_capacity) | Specifies the total maximum number of instances that are allowed to be in the warm pool or in any state except Terminated for the Auto Scaling group. Ignored when 'warm\_pool\_enabled' is false | `number` | `null` | no |
| <a name="input_warm_pool_min_size"></a> [warm\_pool\_min\_size](#input\_warm\_pool\_min\_size) | Specifies the minimum number of instances to maintain in the warm pool. This helps you to ensure that there is always a certain number of warmed instances available to handle traffic spikes. Ignored when 'warm\_pool\_enabled' is false | `number` | `null` | no |
| <a name="input_warm_pool_state"></a> [warm\_pool\_state](#input\_warm\_pool\_state) | Sets the instance state to transition to after the lifecycle hooks finish. Valid values are: Stopped (default) or Running. Ignored when 'warm\_pool\_enabled' is false | `string` | `null` | no |
| <a name="input_workloads_enabled"></a> [workloads\_enabled](#input\_workloads\_enabled) | Configure Workload Subnets, Route Tables, and associations if set to true | `bool` | `false` | no |
| <a name="input_zpa_enabled"></a> [zpa\_enabled](#input\_zpa\_enabled) | Configure Route 53 Subnets, Route Tables, and Resolvers for ZPA DNS redirection | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_testbedconfig"></a> [testbedconfig](#output\_testbedconfig) | AWS Testbed results |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->