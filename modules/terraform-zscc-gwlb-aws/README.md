# Zscaler Cloud Connector / AWS Gateway Load Balancer Module

This module creates a Gateway Load Balancer (GWLB) and Listener resource. It also creates a target group associated with that listener service + target group attachments based on the size of the Cloud Connector instance being deployed.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13.7, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 4.7.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 4.7.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_lb.gwlb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb) | resource |
| [aws_lb_listener.gwlb-listener](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_target_group.gwlb-target-group"](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_lb_target_group_attachment.gwlb-target-group-attachment-small](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group_attachment) | resource |
| [aws_lb_target_group_attachment.gwlb-target-group-attachment-med-lrg-1](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group_attachment) | resource |
| [aws_lb_target_group_attachment.gwlb-target-group-attachment-med-lrg-2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group_attachment) | resource |
| [aws_lb_target_group_attachment.gwlb-target-group-attachment-lrg-3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group_attachment) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="name_prefix"></a> [name\_prefix](#name\_prefix) | A prefix to associate to all the Cloud Connector module resources. | `string` | `null` | no |
| <a name="resource_tag"></a> [resource\_tag](#resource\_tag) | A tag to associate to all the Cloud Connector module resources. | `string` | `null` | no |
| <a name="vpc_id"></a> [vpc\_id](#vpc\_id) | Cloud Connector VPC ID. | `string` | `null` | yes |
| <a name="cc_small_service_ips"></a> [cc\_small\_service\_ips](#cc\_small\_service\_ips) | Cloud Connector Small instance size service IPs to be assigned to target group attachments. Required if cc_instance_size = "small". | `list(string)` | `[]` | no |
| <a name="cc_med_lrg_service_1_ips"></a> [cc\_med\_lrg\_service\_1\_ips](#cc\_med\_lrg\_service\_1\_ips) | Cloud Connector Medium or Large instance size service interface 1 IPs to be assigned to target group attachments. Required if cc_instance_size = "medium" OR "large". | `list(string)` | `[]` | no |
| <a name="cc_med_lrg_service_2_ips"></a> [cc\_med\_lrg\_service\_2\_ips](#cc\_med\_lrg\_service\_1\_ips) | Cloud Connector Medium or Large instance size service interface 2 IPs to be assigned to target group attachments. Required if cc_instance_size = "medium" OR "large". | `list(string)` | `[]` | no |
| <a name="cc_lrg_service_3_ips"></a> [cc\_lrg\_service\_3\_ips](#cc\_lrg\_service\_3\_ips) | Cloud Connector Large instance size service interface 3 IPs to be assigned to target group attachments. Required if cc_instance_size = "large". | `list(string)` | `[]` | no |
| <a name="http_probe_port"></a> [health\_probe\_port](#health\_probe\_port) | Port number for Cloud Connector cloud init to enable listener port for HTTP probe from GWLB Target Group. | `number` | `50000` | no |
| <a name="health_check_interval"></a> [health\_check\_interval](#health\_check\_interval) | Interval for GWLB target group health check probing, in seconds, of Cloud Connector targets. Minimum 5 and maximum 300 seconds. | `number` | `10` | no |
| <a name="healthy_threshold"></a> [healthy\_threshold](#healthy\_threshold) | The number of successful health checks required before an unhealthy target becomes healthy. Minimum 2 and maximum 10. | `number` | `3` | no |
| <a name="unhealthy_threshold"></a> [unhealthy\_threshold](#unhealthy\_threshold) | The number of unsuccessful health checks required before an healthy target becomes unhealthy. Minimum 2 and maximum 10. | `number` | `3` | no |
| <a name="cross_zone_lb_enabled"></a> [cross\_zone\_lb\_enabled](#cross\_zone\_lb\_enabled) | Determines whether GWLB cross zone load balancing should be enabled or not. | `bool` | `false` | no |
| <a name="cc_subnet_ids"></a> [cc\_subnet\_ids](#cc\_subnet\_ids) | List of Subnet IDs to create GWLB in. | `list(string)` | `[]` | yes |
| <a name="global_tags"></a> [global\_tags](#global\_tags) | Populate any custom user defined tags from a map.<br>Example for defining tag Keys and Values:<pre>locals { <br>global_tags = {<br>  Owner = var.owner_tag <br>  ManagedBy = "terraform"<br>}</pre> | `map(string)` | `[]` | no |
| <a name="cc_instance_size"></a> [cc\_instance\_size](#cc\_instance\_size) | Cloud Connector instance size as defined in the Connector portal provisioning template. | `string` | `null` | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="gwlb_arn"></a> [gwlb\_arn](#gwlb\_arn) | ARN of the aws_lb (GLWB) resource |
