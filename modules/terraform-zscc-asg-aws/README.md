# Zscaler Cloud Connector / AWS Autoscaling (Cloud Connector) Module

This module creates a AWS Launch Template, Autoscaling Group, and Policy resources needed to deploy Cloud Connector appliances. It also creates an attachment to a user provided Target Group ARN to associate all instances to a GWLB. Due to the instance based Target Grouping, modifications are done to the NIC order association (0 becoming service and 1 becoming management) as well as the actual GWLB Target Group configuration (IP to Instance).

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13.7, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 4.7.0 |
| <a name="requirement_local"></a> [local](#requirement\_local) | ~> 2.2.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | ~> 3.1.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 4.7.0 |
| <a name="provider_null"></a> [null](#provider\_null) | ~> 3.1.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_autoscaling_attachment.cc_asg_attachment_gwlb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_attachment) | resource |
| [aws_autoscaling_group.cc_asg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group) | resource |
| [aws_autoscaling_policy.cc_asg_target_tracking_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_policy) | resource |
| [aws_launch_template.cc_launch_template](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) | resource |
| [null_resource.error_checker](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [aws_ami.cloudconnector](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cc_instance_size"></a> [cc\_instance\_size](#input\_cc\_instance\_size) | Cloud Connector Instance size. Determined by and needs to match the Cloud Connector Portal provisioning template configuration | `string` | `"small"` | no |
| <a name="input_cc_subnet_ids"></a> [cc\_subnet\_ids](#input\_cc\_subnet\_ids) | Cloud Connector EC2 Instance subnet IDs list | `list(string)` | n/a | yes |
| <a name="input_ccvm_instance_type"></a> [ccvm\_instance\_type](#input\_ccvm\_instance\_type) | Cloud Connector Instance Type | `string` | `"m5.large"` | no |
| <a name="input_global_tags"></a> [global\_tags](#input\_global\_tags) | Populate any custom user defined tags from a map | `map(string)` | `{}` | no |
| <a name="input_health_check_grace_period"></a> [health\_check\_grace\_period](#input\_health\_check\_grace\_period) | The amount of time until EC2 Auto Scaling performs the first health check on new instances after they are put into service. Default is 15 minutes | `number` | `900` | no |
| <a name="input_iam_instance_profile"></a> [iam\_instance\_profile](#input\_iam\_instance\_profile) | IAM instance profile ID assigned to Cloud Connector | `list(string)` | n/a | yes |
| <a name="input_instance_key"></a> [instance\_key](#input\_instance\_key) | SSH Key for instances | `string` | n/a | yes |
| <a name="input_launch_template_version"></a> [launch\_template\_version](#input\_launch\_template\_version) | Launch template version. Can be version number, `$Latest` or `$Default` | `string` | `"$Latest"` | no |
| <a name="input_max_size"></a> [max\_size](#input\_max\_size) | Maxinum number of Cloud Connectors to maintain in Autoscaling group | `number` | `4` | no |
| <a name="input_mgmt_security_group_id"></a> [mgmt\_security\_group\_id](#input\_mgmt\_security\_group\_id) | Cloud Connector EC2 Instance management subnet id | `list(string)` | n/a | yes |
| <a name="input_min_size"></a> [min\_size](#input\_min\_size) | Mininum number of Cloud Connectors to maintain in Autoscaling group | `number` | `2` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | A prefix to associate to all the Cloud Connector module resources | `string` | `null` | no |
| <a name="input_resource_tag"></a> [resource\_tag](#input\_resource\_tag) | A tag to associate to all the Cloud Connector module resources | `string` | `null` | no |
| <a name="input_reuse_on_scale_in"></a> [reuse\_on\_scale\_in](#input\_reuse\_on\_scale\_in) | Specifies whether instances in the Auto Scaling group can be returned to the warm pool on scale in. | `bool` | `"false"` | no |
| <a name="input_service_security_group_id"></a> [service\_security\_group\_id](#input\_service\_security\_group\_id) | Cloud Connector EC2 Instance service subnet id | `list(string)` | n/a | yes |
| <a name="input_target_cpu_util_value"></a> [target\_cpu\_util\_value](#input\_target\_cpu\_util\_value) | Target value number for autoscaling policy CPU utilization target tracking. ie: trigger a scale in/out to keep average CPU Utliization percentage across all instances at/under this number | `number` | `70` | no |
| <a name="input_target_group_arn"></a> [target\_group\_arn](#input\_target\_group\_arn) | ARN of GWLB Target Group for cloud connectors to be registered | `string` | n/a | yes |
| <a name="input_target_tracking_metric"></a> [target\_tracking\_metric](#input\_target\_tracking\_metric) | The AWS ASG pre-defined target tracking metric type. Cloud Connector recommends ASGAverageCPUUtilization | `string` | `"ASGAverageCPUUtilization"` | no |
| <a name="input_user_data"></a> [user\_data](#input\_user\_data) | Cloud Init data | `string` | n/a | yes |
| <a name="input_warm_pool_enabled"></a> [warm\_pool\_enabled](#input\_warm\_pool\_enabled) | If set to true, add a warm pool to the specified Auto Scaling group. See [warm\_pool](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group#warm_pool). | `bool` | `"false"` | no |
| <a name="input_warm_pool_max_group_prepared_capacity"></a> [warm\_pool\_max\_group\_prepared\_capacity](#input\_warm\_pool\_max\_group\_prepared\_capacity) | Specifies the total maximum number of instances that are allowed to be in the warm pool or in any state except Terminated for the Auto Scaling group. Ignored when 'warm\_pool\_enabled' is false | `number` | `null` | no |
| <a name="input_warm_pool_min_size"></a> [warm\_pool\_min\_size](#input\_warm\_pool\_min\_size) | Specifies the minimum number of instances to maintain in the warm pool. This helps you to ensure that there is always a certain number of warmed instances available to handle traffic spikes. Ignored when 'warm\_pool\_enabled' is false | `number` | `null` | no |
| <a name="input_warm_pool_state"></a> [warm\_pool\_state](#input\_warm\_pool\_state) | Sets the instance state to transition to after the lifecycle hooks finish. Valid values are: Stopped (default) or Running. Ignored when 'warm\_pool\_enabled' is false | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_availability_zone"></a> [availability\_zone](#output\_availability\_zone) | Availability zones used for ASG |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
