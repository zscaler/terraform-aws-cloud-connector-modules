# Zscaler Cloud Connector / AWS Autoscaling (Cloud Connector) Module

This module creates a AWS Launch Template, Autoscaling Group, and Policy resources needed to deploy Cloud Connector appliances. It also creates an attachment to a user provided Target Group ARN to associate all instances to a GWLB. Due to the instance based Target Grouping, modifications are done to the NIC order association (0 becoming service and 1 becoming management) as well as the actual GWLB Target Group configuration (IP to Instance).

## Considerations

If sns_enabled to set to true where an sns topic AND sns topic subscription (for email alerts on ASG instance actions) are created, all email address endpoints will receive a subscription confirmation email from AWS. If a terraform destroy operation is performed without all subscriptions confirmed, it will succeed but the SNS subscription(s) will be ignored from destroy and remain in a "Pending Confirmation" state. AWS should automatically delete the pending subscription after a few days. See [Partially Supported values](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription#:~:text=for%20protocol%20include%3A-,NOTE%3A,remove%20the%20subscription%20from%20AWS.%20The%20pending_confirmation%20attribute%20provides%20confirmation%20status.,-email%20%2D%20Delivers%20messages)




<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13.7, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.59, <= 5.17 |
| <a name="requirement_local"></a> [local](#requirement\_local) | ~> 2.2.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | ~> 3.1.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.59, <= 5.17 |
| <a name="provider_null"></a> [null](#provider\_null) | ~> 3.1.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_autoscaling_attachment.cc_asg_attachment_gwlb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_attachment) | resource |
| [aws_autoscaling_group.cc_asg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group) | resource |
| [aws_autoscaling_notification.cc_asg_notifications](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_notification) | resource |
| [aws_autoscaling_policy.cc_asg_cpu_utilization_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_policy) | resource |
| [aws_launch_template.cc_launch_template](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) | resource |
| [aws_sns_topic.cc_asg_topic](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic_subscription.cc_asg_topic_email_subscription](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource |
| [null_resource.error_checker](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [aws_ebs_default_kms_key.current_kms_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ebs_default_kms_key) | data source |
| [aws_kms_alias.current_kms_arn](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/kms_alias) | data source |
| [aws_sns_topic.cc_asg_topic_selected](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/sns_topic) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ami_id"></a> [ami\_id](#input\_ami\_id) | AMI ID(s) to be used for deploying Cloud Connector appliances. Ideally all VMs should be on the same AMI ID as templates always pull the latest from AWS Marketplace. This variable is provided if a customer desires to override/retain an old ami for existing deployments rather than upgrading and forcing a launch template change. | `list(string)` | n/a | yes |
| <a name="input_byo_kms_key_alias"></a> [byo\_kms\_key\_alias](#input\_byo\_kms\_key\_alias) | Requires var.ebs\_encryption\_enabled to be true. Set to null by default which is the AWS default managed/master key. Set as 'alias/<key-alias>' to use a custom KMS key | `string` | `null` | no |
| <a name="input_byo_sns_topic"></a> [byo\_sns\_topic](#input\_byo\_sns\_topic) | Determine whether or not to create an AWS SNS topic and topic subscription for email alerts. Setting this variable to true implies you should also set variable sns\_enabled to true | `bool` | `false` | no |
| <a name="input_byo_sns_topic_name"></a> [byo\_sns\_topic\_name](#input\_byo\_sns\_topic\_name) | Existing SNS Topic friendly name to be used for autoscaling group notifications | `string` | `""` | no |
| <a name="input_cc_instance_size"></a> [cc\_instance\_size](#input\_cc\_instance\_size) | Cloud Connector Instance size. Determined by and needs to match the Cloud Connector Portal provisioning template configuration | `string` | `"small"` | no |
| <a name="input_cc_subnet_ids"></a> [cc\_subnet\_ids](#input\_cc\_subnet\_ids) | Cloud Connector EC2 Instance subnet IDs list | `list(string)` | n/a | yes |
| <a name="input_ccvm_instance_type"></a> [ccvm\_instance\_type](#input\_ccvm\_instance\_type) | Cloud Connector Instance Type | `string` | `"m6i.large"` | no |
| <a name="input_ebs_encryption_enabled"></a> [ebs\_encryption\_enabled](#input\_ebs\_encryption\_enabled) | true/false whether to enable EBS encryption on the root volume. Default is true | `bool` | `true` | no |
| <a name="input_ebs_volume_type"></a> [ebs\_volume\_type](#input\_ebs\_volume\_type) | (Optional) Type of volume. Valid values include standard, gp2, gp3, io1, io2, sc1, or st1. Defaults to gp3 | `string` | `"gp3"` | no |
| <a name="input_global_tags"></a> [global\_tags](#input\_global\_tags) | Populate any custom user defined tags from a map | `map(string)` | `{}` | no |
| <a name="input_health_check_grace_period"></a> [health\_check\_grace\_period](#input\_health\_check\_grace\_period) | The amount of time until EC2 Auto Scaling performs the first health check on new instances after they are put into service. With lifecycle hooks it is immediate. Otheriwse Default is 15 minutes | `number` | `0` | no |
| <a name="input_health_check_type"></a> [health\_check\_type](#input\_health\_check\_type) | EC2 or ELB. Controls how health checking is done | `string` | `"EC2"` | no |
| <a name="input_iam_instance_profile"></a> [iam\_instance\_profile](#input\_iam\_instance\_profile) | IAM instance profile ID assigned to Cloud Connector | `list(string)` | n/a | yes |
| <a name="input_imdsv2_enabled"></a> [imdsv2\_enabled](#input\_imdsv2\_enabled) | true/false whether to force IMDSv2 only for instance bring up. Default is true | `bool` | `true` | no |
| <a name="input_instance_key"></a> [instance\_key](#input\_instance\_key) | SSH Key for instances | `string` | n/a | yes |
| <a name="input_instance_warmup"></a> [instance\_warmup](#input\_instance\_warmup) | Amount of time, in seconds, until a newly launched instance can contribute to the Amazon CloudWatch metrics. This delay lets an instance finish initializing before Amazon EC2 Auto Scaling aggregates instance metrics, resulting in more reliable usage data. Set this value equal to the amount of time that it takes for resource consumption to become stable after an instance reaches the InService state | `number` | `0` | no |
| <a name="input_launch_template_version"></a> [launch\_template\_version](#input\_launch\_template\_version) | Launch template version. Can be version number, `$Latest` or `$Default` | `string` | `"$Latest"` | no |
| <a name="input_lifecyclehook_instance_launch_wait_time"></a> [lifecyclehook\_instance\_launch\_wait\_time](#input\_lifecyclehook\_instance\_launch\_wait\_time) | The maximum amount of time to wait in pending:wait state on instance launch in warmpool | `number` | `1800` | no |
| <a name="input_lifecyclehook_instance_terminate_wait_time"></a> [lifecyclehook\_instance\_terminate\_wait\_time](#input\_lifecyclehook\_instance\_terminate\_wait\_time) | The maximum amount of time to wait in terminating:wait state on instance termination | `number` | `900` | no |
| <a name="input_max_size"></a> [max\_size](#input\_max\_size) | Maxinum number of Cloud Connectors to maintain in Autoscaling group | `number` | `4` | no |
| <a name="input_mgmt_security_group_id"></a> [mgmt\_security\_group\_id](#input\_mgmt\_security\_group\_id) | Cloud Connector EC2 Instance management subnet id | `list(string)` | n/a | yes |
| <a name="input_min_size"></a> [min\_size](#input\_min\_size) | Mininum number of Cloud Connectors to maintain in Autoscaling group | `number` | `2` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | A prefix to associate to all the Cloud Connector module resources | `string` | `null` | no |
| <a name="input_protect_from_scale_in"></a> [protect\_from\_scale\_in](#input\_protect\_from\_scale\_in) | Whether newly launched instances are automatically protected from termination by Amazon EC2 Auto Scaling when scaling in. For more information about preventing instances from terminating on scale in, see Using instance scale-in protection in the Amazon EC2 Auto Scaling User Guide | `bool` | `false` | no |
| <a name="input_resource_tag"></a> [resource\_tag](#input\_resource\_tag) | A tag to associate to all the Cloud Connector module resources | `string` | `null` | no |
| <a name="input_reuse_on_scale_in"></a> [reuse\_on\_scale\_in](#input\_reuse\_on\_scale\_in) | Specifies whether instances in the Auto Scaling group can be returned to the warm pool on scale in. | `bool` | `false` | no |
| <a name="input_service_security_group_id"></a> [service\_security\_group\_id](#input\_service\_security\_group\_id) | Cloud Connector EC2 Instance service subnet id | `list(string)` | n/a | yes |
| <a name="input_sns_email_list"></a> [sns\_email\_list](#input\_sns\_email\_list) | List of email addresses to input for sns topic subscriptions for autoscaling group notifications. Required if sns\_enabled variable is true and byo\_sns\_topic false | `list(string)` | <pre>[<br>  ""<br>]</pre> | no |
| <a name="input_sns_enabled"></a> [sns\_enabled](#input\_sns\_enabled) | Determine whether or not to create autoscaling group notifications. Default is false. If setting this value to true, terraform will also create a new sns topic and topic subscription | `bool` | `false` | no |
| <a name="input_target_cpu_util_value"></a> [target\_cpu\_util\_value](#input\_target\_cpu\_util\_value) | Target value number for autoscaling policy CPU utilization target tracking. ie: trigger a scale in/out to keep average CPU Utliization percentage across all instances at/under this number | `number` | `80` | no |
| <a name="input_target_group_arn"></a> [target\_group\_arn](#input\_target\_group\_arn) | ARN of GWLB Target Group for cloud connectors to be registered | `string` | n/a | yes |
| <a name="input_user_data"></a> [user\_data](#input\_user\_data) | Cloud Init data | `string` | n/a | yes |
| <a name="input_wait_for_capacity_timeout"></a> [wait\_for\_capacity\_timeout](#input\_wait\_for\_capacity\_timeout) | Maximum duration that Terraform should wait for ASG instances to be healthy before timing out | `string` | `"0"` | no |
| <a name="input_warm_pool_enabled"></a> [warm\_pool\_enabled](#input\_warm\_pool\_enabled) | If set to true, add a warm pool to the specified Auto Scaling group. See [warm\_pool](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group#warm_pool). | `bool` | `false` | no |
| <a name="input_warm_pool_max_group_prepared_capacity"></a> [warm\_pool\_max\_group\_prepared\_capacity](#input\_warm\_pool\_max\_group\_prepared\_capacity) | Specifies the total maximum number of instances that are allowed to be in the warm pool or in any state except Terminated for the Auto Scaling group. Ignored when 'warm\_pool\_enabled' is false | `number` | `null` | no |
| <a name="input_warm_pool_min_size"></a> [warm\_pool\_min\_size](#input\_warm\_pool\_min\_size) | Specifies the minimum number of instances to maintain in the warm pool. This helps you to ensure that there is always a certain number of warmed instances available to handle traffic spikes. Ignored when 'warm\_pool\_enabled' is false | `number` | `0` | no |
| <a name="input_warm_pool_state"></a> [warm\_pool\_state](#input\_warm\_pool\_state) | Sets the instance state to transition to after the lifecycle hooks finish. Valid values are: Stopped (default) or Running. Ignored when 'warm\_pool\_enabled' is false | `string` | `"Stopped"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_autoscaling_group_ids"></a> [autoscaling\_group\_ids](#output\_autoscaling\_group\_ids) | Autoscaling group ID |
| <a name="output_availability_zone"></a> [availability\_zone](#output\_availability\_zone) | Availability zones used for ASG |
| <a name="output_launch_template_id"></a> [launch\_template\_id](#output\_launch\_template\_id) | Autoscaling Launch Template ID |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
