# Zscaler Cloud Connector / AWS Gateway Load Balancer Module

This module creates a Gateway Load Balancer (GWLB) and Listener resource. It also creates a target group associated with that listener service + target group attachments based on the size of the Cloud Connector instance being deployed.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13.7, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 4.59.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 4.59.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_lb.gwlb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb) | resource |
| [aws_lb_listener.gwlb_listener](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_target_group.gwlb_target_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_lb_target_group_attachment.gwlb_target_group_attachment_lrg_3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group_attachment) | resource |
| [aws_lb_target_group_attachment.gwlb_target_group_attachment_med_lrg_1](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group_attachment) | resource |
| [aws_lb_target_group_attachment.gwlb_target_group_attachment_med_lrg_2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group_attachment) | resource |
| [aws_lb_target_group_attachment.gwlb_target_group_attachment_small](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group_attachment) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cc_instance_size"></a> [cc\_instance\_size](#input\_cc\_instance\_size) | Cloud Connector instance size as defined in the Connector portal provisioning template | `string` | `"small"` | no |
| <a name="input_cc_lrg_service_3_ips"></a> [cc\_lrg\_service\_3\_ips](#input\_cc\_lrg\_service\_3\_ips) | Cloud Connector Large instance size service-3 IPs | `list(string)` | `[]` | no |
| <a name="input_cc_med_lrg_service_1_ips"></a> [cc\_med\_lrg\_service\_1\_ips](#input\_cc\_med\_lrg\_service\_1\_ips) | Cloud Connector Medium/Large instance size service-1 IPs | `list(string)` | `[]` | no |
| <a name="input_cc_med_lrg_service_2_ips"></a> [cc\_med\_lrg\_service\_2\_ips](#input\_cc\_med\_lrg\_service\_2\_ips) | Cloud Connector Medium/Large instance size service-2 IPs | `list(string)` | `[]` | no |
| <a name="input_cc_small_service_ips"></a> [cc\_small\_service\_ips](#input\_cc\_small\_service\_ips) | Cloud Connector Small instance size service IPs | `list(string)` | `[]` | no |
| <a name="input_cc_subnet_ids"></a> [cc\_subnet\_ids](#input\_cc\_subnet\_ids) | Cloud Connector subnet IDs list | `list(string)` | n/a | yes |
| <a name="input_cross_zone_lb_enabled"></a> [cross\_zone\_lb\_enabled](#input\_cross\_zone\_lb\_enabled) | Determines whether GWLB cross zone load balancing should be enabled or not | `bool` | `false` | no |
| <a name="input_deregistration_delay"></a> [deregistration\_delay](#input\_deregistration\_delay) | Amount time for Elastic Load Balancing to wait before changing the state of a deregistering target from draining to unused. The range is 0-3600 seconds. | `number` | `0` | no |
| <a name="input_flow_stickiness"></a> [flow\_stickiness](#input\_flow\_stickiness) | Options are (Default) 5-tuple (src ip/src port/dest ip/dest port/protocol), 3-tuple (src ip/dest ip/protocol), or 2-tuple (src ip/dest ip) | `string` | `"5-tuple"` | no |
| <a name="input_global_tags"></a> [global\_tags](#input\_global\_tags) | Populate any custom user defined tags from a map | `map(string)` | `{}` | no |
| <a name="input_gwlb_name"></a> [gwlb\_name](#input\_gwlb\_name) | GWLB resource and tag name | `string` | n/a | yes |
| <a name="input_health_check_interval"></a> [health\_check\_interval](#input\_health\_check\_interval) | Interval for GWLB target group health check probing, in seconds, of Cloud Connector targets. Minimum 5 and maximum 300 seconds | `number` | `10` | no |
| <a name="input_healthy_threshold"></a> [healthy\_threshold](#input\_healthy\_threshold) | The number of successful health checks required before an unhealthy target becomes healthy. Minimum 2 and maximum 10 | `number` | `2` | no |
| <a name="input_http_probe_port"></a> [http\_probe\_port](#input\_http\_probe\_port) | Port number for Cloud Connector cloud init to enable listener port for HTTP probe from GWLB Target Group | `number` | `50000` | no |
| <a name="input_rebalance_enabled"></a> [rebalance\_enabled](#input\_rebalance\_enabled) | Indicates how the GWLB handles existing flows when a target is deregistered or marked unhealthy. true means rebalance. false means no\_rebalance. Default: true | `bool` | `true` | no |
| <a name="input_target_group_name"></a> [target\_group\_name](#input\_target\_group\_name) | GWLB Target Group resource name | `string` | n/a | yes |
| <a name="input_unhealthy_threshold"></a> [unhealthy\_threshold](#input\_unhealthy\_threshold) | The number of unsuccessful health checks required before an healthy target becomes unhealthy. Minimum 2 and maximum 10 | `number` | `3` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | Cloud Connector VPC ID | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_gwlb_arn"></a> [gwlb\_arn](#output\_gwlb\_arn) | GWLB ARN |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
