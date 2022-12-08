# Zscaler Cloud Connector / AWS Autoscaling (Cloud Connector) Module

This module creates a AWS Launch Template, Autoscaling Group, and Policy resources needed to deploy Cloud Connector appliances. It also creates an attachment to a user provided Target Group ARN to associate all instances to a GWLB. Due to the instance based Target Grouping, modifications are done to the NIC order association (0 becoming service and 1 becoming management) as well as the actual GWLB Target Group configuration (IP to Instance).

## Considerations

If sns_enabled to set to true where an sns topic AND sns topic subscription (for email alerts on ASG instance actions) are created, all email address endpoints will receive a subscription confirmation email from AWS. If a terraform destroy operation is performed without all subscriptions confirmed, it will succeed but the SNS subscription(s) will be ignored from destroy and remain in a "Pending Confirmation" state. AWS should automatically delete the pending subscription after a few days. See [Partially Supported values](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription#:~:text=for%20protocol%20include%3A-,NOTE%3A,remove%20the%20subscription%20from%20AWS.%20The%20pending_confirmation%20attribute%20provides%20confirmation%20status.,-email%20%2D%20Delivers%20messages)




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
| [aws_autoscaling_lifecycle_hook.cc_asg_lifecyclehook_launch](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_lifecycle_hook) | resource |
| [aws_autoscaling_lifecycle_hook.cc_asg_lifecyclehook_terminate](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_lifecycle_hook) | resource |
| [aws_autoscaling_notification.cc_asg_notifications](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_notification) | resource |
| [aws_autoscaling_policy.cc_asg_target_tracking_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_policy) | resource |
| [aws_launch_template.cc_launch_template](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) | resource |
| [aws_sns_topic.cc_asg_topic](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic_subscription.cc_asg_topic_email_subscription](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource |
| [null_resource.error_checker](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_sns_topic.cc_asg_topic_selected](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/sns_topic) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_byo_sns_topic"></a> [byo\_sns\_topic](#input\_byo\_sns\_topic) | Determine whether or not to create an AWS SNS topic and topic subscription for email alerts. Setting this variable to true implies you should also set variable sns\_enabled to true | `bool` | `false` | no |
| <a name="input_byo_sns_topic_name"></a> [byo\_sns\_topic\_name](#input\_byo\_sns\_topic\_name) | Existing SNS Topic friendly name to be used for autoscaling group notifications | `string` | `""` | no |
| <a name="input_cc_instance_size"></a> [cc\_instance\_size](#input\_cc\_instance\_size) | Cloud Connector Instance size. Determined by and needs to match the Cloud Connector Portal provisioning template configuration | `string` | `"small"` | no |
| <a name="input_cc_subnet_ids"></a> [cc\_subnet\_ids](#input\_cc\_subnet\_ids) | Cloud Connector EC2 Instance subnet IDs list | `list(string)` | n/a | yes |
| <a name="input_ccvm_instance_type"></a> [ccvm\_instance\_type](#input\_ccvm\_instance\_type) | Cloud Connector Instance Type | `string` | `"m5.large"` | no |
| <a name="input_global_tags"></a> [global\_tags](#input\_global\_tags) | Populate any custom user defined tags from a map | `map(string)` | `{}` | no |
| <a name="input_health_check_grace_period"></a> [health\_check\_grace\_period](#input\_health\_check\_grace\_period) | The amount of time until EC2 Auto Scaling performs the first health check on new instances after they are put into service. Default is 15 minutes | `number` | `900` | no |
| <a name="input_iam_instance_profile"></a> [iam\_instance\_profile](#input\_iam\_instance\_profile) | IAM instance profile ID assigned to Cloud Connector | `list(string)` | n/a | yes |
| <a name="input_instance_key"></a> [instance\_key](#input\_instance\_key) | SSH Key for instances | `string` | n/a | yes |
| <a name="input_launch_template_version"></a> [launch\_template\_version](#input\_launch\_template\_version) | Launch template version. Can be version number, `$Latest` or `$Default` | `string` | `"$Latest"` | no |
| <a name="input_lifecyclehook_instance_launch_wait_time"></a> [lifecyclehook\_instance\_launch\_wait\_time](#input\_lifecyclehook\_instance\_launch\_wait\_time) | The maximum amount of time to wait in pending:wait state on instance launch in warmpool | `number` | `600` | no |
| <a name="input_lifecyclehook_instance_terminate_wait_time"></a> [lifecyclehook\_instance\_terminate\_wait\_time](#input\_lifecyclehook\_instance\_terminate\_wait\_time) | The maximum amount of time to wait in terminating:wait state on instance termination | `number` | `600` | no |
| <a name="input_max_size"></a> [max\_size](#input\_max\_size) | Maxinum number of Cloud Connectors to maintain in Autoscaling group | `number` | `4` | no |
| <a name="input_mgmt_security_group_id"></a> [mgmt\_security\_group\_id](#input\_mgmt\_security\_group\_id) | Cloud Connector EC2 Instance management subnet id | `list(string)` | n/a | yes |
| <a name="input_min_size"></a> [min\_size](#input\_min\_size) | Mininum number of Cloud Connectors to maintain in Autoscaling group | `number` | `2` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | A prefix to associate to all the Cloud Connector module resources | `string` | `null` | no |
| <a name="input_private_amis"></a> [private\_amis](#input\_private\_amis) | Map of Zscaler Cloud Connector Private AMIs | `map(any)` | <pre>{<br>  "eu-central-1": "ami-00fdd9a35e268bfdf",<br>  "eu-west-1": "ami-0386414112742b530",<br>  "us-east-1": "ami-0c65ee5c52372f8fc",<br>  "us-east-2": "ami-0e0c0ecd08b6d1abd",<br>  "us-west-2": "ami-0f3dfa57203b38e81"<br>}</pre> | no |
| <a name="input_resource_tag"></a> [resource\_tag](#input\_resource\_tag) | A tag to associate to all the Cloud Connector module resources | `string` | `null` | no |
| <a name="input_reuse_on_scale_in"></a> [reuse\_on\_scale\_in](#input\_reuse\_on\_scale\_in) | Specifies whether instances in the Auto Scaling group can be returned to the warm pool on scale in. | `bool` | `false` | no |
| <a name="input_service_security_group_id"></a> [service\_security\_group\_id](#input\_service\_security\_group\_id) | Cloud Connector EC2 Instance service subnet id | `list(string)` | n/a | yes |
| <a name="input_sns_email_list"></a> [sns\_email\_list](#input\_sns\_email\_list) | List of email addresses to input for sns topic subscriptions for autoscaling group notifications. Required if sns\_enabled variable is true and byo\_sns\_topic false | `list(string)` | <pre>[<br>  ""<br>]</pre> | no |
| <a name="input_sns_enabled"></a> [sns\_enabled](#input\_sns\_enabled) | Determine whether or not to create autoscaling group notifications. Default is false. If setting this value to true, terraform will also create a new sns topic and topic subscription | `bool` | `false` | no |
| <a name="input_target_cpu_util_value"></a> [target\_cpu\_util\_value](#input\_target\_cpu\_util\_value) | Target value number for autoscaling policy CPU utilization target tracking. ie: trigger a scale in/out to keep average CPU Utliization percentage across all instances at/under this number | `number` | `20` | no |
| <a name="input_target_group_arn"></a> [target\_group\_arn](#input\_target\_group\_arn) | ARN of GWLB Target Group for cloud connectors to be registered | `string` | n/a | yes |
| <a name="input_target_tracking_metric"></a> [target\_tracking\_metric](#input\_target\_tracking\_metric) | The AWS ASG pre-defined target tracking metric type. Cloud Connector recommends ASGAverageCPUUtilization | `string` | `"ASGAverageCPUUtilization"` | no |
| <a name="input_user_data"></a> [user\_data](#input\_user\_data) | Cloud Init data | `string` | n/a | yes |
| <a name="input_warm_pool_enabled"></a> [warm\_pool\_enabled](#input\_warm\_pool\_enabled) | If set to true, add a warm pool to the specified Auto Scaling group. See [warm\_pool](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group#warm_pool). | `bool` | `false` | no |
| <a name="input_warm_pool_max_group_prepared_capacity"></a> [warm\_pool\_max\_group\_prepared\_capacity](#input\_warm\_pool\_max\_group\_prepared\_capacity) | Specifies the total maximum number of instances that are allowed to be in the warm pool or in any state except Terminated for the Auto Scaling group. Ignored when 'warm\_pool\_enabled' is false | `number` | `null` | no |
| <a name="input_warm_pool_min_size"></a> [warm\_pool\_min\_size](#input\_warm\_pool\_min\_size) | Specifies the minimum number of instances to maintain in the warm pool. This helps you to ensure that there is always a certain number of warmed instances available to handle traffic spikes. Ignored when 'warm\_pool\_enabled' is false | `number` | `null` | no |
| <a name="input_warm_pool_state"></a> [warm\_pool\_state](#input\_warm\_pool\_state) | Sets the instance state to transition to after the lifecycle hooks finish. Valid values are: Stopped (default) or Running. Ignored when 'warm\_pool\_enabled' is false | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_availability_zone"></a> [availability\_zone](#output\_availability\_zone) | Availability zones used for ASG |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
