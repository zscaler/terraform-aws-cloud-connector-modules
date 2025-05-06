# Zscaler Cloud Connector / AWS IAM Module

This module creates IAM Policies, Roles, and Instance Profile resources required for successful Cloud Connector deployments. As part of Zscaler provided deployment templates most resources have conditional create options leveraged "byo" variables should a customer want to leverage the module outputs with data reference to resources that may already exist in their AWS environment.


|Policy Name|Dependency|<center>Action</center>|<center>Resource/Scope</center>|Deployment Type (asg/non-asg/both)|<center>Description</center>|
|:--:|:--:|:--|:--|:--:|:--|
| CCAssumeRole | Required | [<br/>"sts:AssumeRole"<br/>] | Service:ec2.amazonaws.com | Both | Policy which permits CC Control Plan to assume IAM Identity|
| CCPermitGetSecrets | Required | [<br/>"secretsmanager:GetSecretValue"<br/>] | ID of Secrets Manager Name | Both | Policy which permits CCs to retrieve and decrypt the encrypted data from Secrets Manager|
| CCPermitSSMSessionManager | Optional |[<br/>"ssm:UpdateInstanceInformation",<br/>"ssmmessages:CreateControlChannel",<br/>"ssmmessages:CreateDataChannel",<br/>"ssmmessages:OpenControlChannel",<br/>"ssmmessages:OpenDataChannel",<br/>] | <center>["*"]</center> | Both | Policy which permits CCs to register to SSM Manager for Console Connect functionality"|
| ASGAllowDescribe | Required | [<br/>"ec2:DescribeInstanceStatus",<br/>"autoscaling:DescribeLifecycleHookTypes",<br/>"autoscaling:DescribeLifecycleHooks",<br/>"autoscaling:DescribeAutoScalingInstances"<br/>]| <center>["*"]</center> | ASG | Policy which permits CCs to send lifecycle actions when hook is enabled|
| ASGAllowAutoscaleLifecycleActions | Required | [<br/>"autoscaling:CompleteLifecycleAction",<br/>"autoscaling:RecordLifecycleActionHeartbeat"<br/>]| List of ASG ARNs recommended | ASG | Policy which permits CCs to send lifecycle actions when hook is enabled|
| CCAllowCloudWatchMetricsRW | Required | [<br/>"cloudwatch:PutMetricData"<br/>]|condition {<br/>test = "StringEquals"<br/>variable = "cloudwatch:namespace"<br/>values =["Zscaler/CloudConnectors"]<br/>}| ASG | Policy which permits CCs to send custom metrics to CloudWatch|
| CCAllowCloudWatchMetricsRO | Required | [<br/>"cloudwatch:GetMetricStatistics",<br/>"cloudwatch:ListMetrics"<br/>]| <center>["*"]</center>| ASG | Policy which permits CCs to send custom metrics to CloudWatch|
| CCAllowEC2DescribeTags | Required | [<br/>"ec2:DescribeTags"<br/>]| <center>["*"]</center> | ASG | Policy which permits CCs to send custom metrics to CloudWatch|
| CCAllowTags | Optional | [<br/>"sns:ListTopics",<br/>"sns:ListSubscriptions",<br/>"sns:Subscribe",<br/>"sns:Unsubscribe",<br/>"sqs:CreateQueue",<br/>"sqs:DeleteQueue"<br/>]| <center>["*"]</center> | Both | Policy which permits CCs to subscribe for tags changes|


<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13.7, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.32 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.32 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_instance_profile.cc_host_profile](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_policy.cc_autoscale_lifecycle_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.cc_get_secrets_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.cc_metrics_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.cc_session_manager_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.cc_tags_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.cc_node_iam_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.cc_autoscale_lifecycle_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.cc_get_secrets_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.cc_metrics_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.cc_session_manager_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.cc_tags_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_instance_profile.cc_host_profile_selected](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_instance_profile) | data source |
| [aws_iam_policy_document.cc_autoscale_lifecycle_policy_document](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.cc_get_secrets_policy_document](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.cc_metrics_policy_document](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.cc_session_manager_policy_document](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.cc_tags_policy_document](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.instance_assume_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_secretsmanager_secret.cc_secret_name](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_asg_arns"></a> [asg\_arns](#input\_asg\_arns) | Recommended: Cloud Connector Autoscaling Group ARN(s) provided for IAM Policy Lifecycle least privilege. If no ARNs are provided, IAM Policy will default to any | `list(string)` | `null` | no |
| <a name="input_asg_enabled"></a> [asg\_enabled](#input\_asg\_enabled) | Determines whether or not to create the cc\_autoscale\_lifecycle\_policy IAM Policy and attach it to the CC IAM Role | `bool` | `false` | no |
| <a name="input_byo_iam"></a> [byo\_iam](#input\_byo\_iam) | Bring your own IAM Instance Profile for Cloud Connector. Setting this variable to true will effectively instruct this module to not create any resources and only reference data resources from values provided in byo\_iam\_instance\_profile\_id | `bool` | `false` | no |
| <a name="input_byo_iam_instance_profile_id"></a> [byo\_iam\_instance\_profile\_id](#input\_byo\_iam\_instance\_profile\_id) | Existing IAM Instance Profile IDs for Cloud Connector association | `list(string)` | `null` | no |
| <a name="input_cloud_tags_enabled"></a> [cloud\_tags\_enabled](#input\_cloud\_tags\_enabled) | Determines whether or not to create the cc\_tags\_policy IAM Policy and attach it to the CC IAM Role | `bool` | `false` | no |
| <a name="input_global_tags"></a> [global\_tags](#input\_global\_tags) | Populate any custom user defined tags from a map | `map(string)` | `{}` | no |
| <a name="input_iam_count"></a> [iam\_count](#input\_iam\_count) | Default number IAM roles/policies/profiles to create | `number` | `1` | no |
| <a name="input_iam_tags_condition"></a> [iam\_tags\_condition](#input\_iam\_tags\_condition) | Optional - customizable conditions map to be used with IAM policies such as KeyTag validation | <pre>map(object({<br/>    test     = string<br/>    variable = string<br/>    values   = list(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | A prefix to associate to all the Cloud Connector IAM module resources | `string` | `null` | no |
| <a name="input_resource_tag"></a> [resource\_tag](#input\_resource\_tag) | A tag to associate to all the Cloud Connector IAM module resources | `string` | `null` | no |
| <a name="input_secret_name"></a> [secret\_name](#input\_secret\_name) | AWS Secrets Manager Secret Name for Cloud Connector provisioning | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_iam_instance_profile_arn"></a> [iam\_instance\_profile\_arn](#output\_iam\_instance\_profile\_arn) | IAM Instance Profile ARN |
| <a name="output_iam_instance_profile_id"></a> [iam\_instance\_profile\_id](#output\_iam\_instance\_profile\_id) | IAM Instance Profile Name |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
