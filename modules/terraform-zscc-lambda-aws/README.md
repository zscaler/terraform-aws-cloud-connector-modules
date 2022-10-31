# Zscaler Cloud Connector / AWS Lambda Module

This module creates all the necessary IAM Roles/Polices, Lambda Functions/Permissions, and Cloudwatch Events required for a successful Cloud Connector HA/Lambda deployment. The intent of this module is to provide inputs for a pair of Cloud Connectors as well as private/workload route tables currently forwarding default route traffic to each respectively. Lambda monitors the health status of both Cloud Connectors and automatically updates the workload route tables to forward traffic to the healthy Cloud Connector in the event one goes down.<br> 

*** For production deployments and better scaling/resliency, we highly advise leveraging Gateway Load Balancer (GWLB) rather than this Lambda.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13.7, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 4.7.0 |
| <a name="requirement_local"></a> [local](#requirement\_local) | ~> 2.2.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 4.7.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_event_rule.cc_checker_timer](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_rule.cc_state_change](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.check_instances_async](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_cloudwatch_event_target.check_state_every1min](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_cloudwatch_log_group.checker_log_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_iam_policy.iam_policy_for_cc_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.iam_for_cc_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.cc_lambda_execution_role_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_lambda_function.cc_route_updater_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_permission.allow_state_checker_to_call_cc_checker_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_lambda_permission.allow_timer_to_call_cc_checker_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_security_group.lambda_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_subnet.cc_subnets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cc_subnet_ids"></a> [cc\_subnet\_ids](#input\_cc\_subnet\_ids) | List of Cloud Connector service subnet IDs | `list(string)` | n/a | yes |
| <a name="input_cc_vm1_id"></a> [cc\_vm1\_id](#input\_cc\_vm1\_id) | Cloud Connector 1 instance id | `string` | n/a | yes |
| <a name="input_cc_vm1_rte_list"></a> [cc\_vm1\_rte\_list](#input\_cc\_vm1\_rte\_list) | List of route tables using Cloud Connector 1 instance id | `list(string)` | n/a | yes |
| <a name="input_cc_vm2_id"></a> [cc\_vm2\_id](#input\_cc\_vm2\_id) | Cloud Connector 2 instance id | `string` | n/a | yes |
| <a name="input_cc_vm2_rte_list"></a> [cc\_vm2\_rte\_list](#input\_cc\_vm2\_rte\_list) | List of route tables using Cloud Connector 2 instance id | `list(string)` | n/a | yes |
| <a name="input_global_tags"></a> [global\_tags](#input\_global\_tags) | Populate any custom user defined tags from a map | `map(string)` | `{}` | no |
| <a name="input_http_probe_port"></a> [http\_probe\_port](#input\_http\_probe\_port) | HTTP port to send the health probes on Cloud Connector cloud | `number` | `50000` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | A prefix to associate to all Cloud Connector Lambda module resources | `string` | `null` | no |
| <a name="input_resource_tag"></a> [resource\_tag](#input\_resource\_tag) | A tag to associate to all Cloud Connector Lambda module resources | `string` | `null` | no |
| <a name="input_route_updater_filename"></a> [route\_updater\_filename](#input\_route\_updater\_filename) | Route updater lambda deployment package filename | `string` | `"rte_updater_lambda.py.zip"` | no |
| <a name="input_route_updater_handler"></a> [route\_updater\_handler](#input\_route\_updater\_handler) | Route updater lambda handler | `string` | `"rte_updater_lambda.lambda_handler"` | no |
| <a name="input_route_updater_runtime"></a> [route\_updater\_runtime](#input\_route\_updater\_runtime) | Route updater lambda runtime | `string` | `"python3.8"` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID for the Route 53 Endpoints | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
