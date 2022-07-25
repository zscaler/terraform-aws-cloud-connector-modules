# Zscaler Cloud Connector / AWS Gateway Load Balancer Endpoint and Endpoint Service Module

This module creates Gateway Load Balancer Endpoint (GWLBE) and VPC Endpoint Service for GWLB resources. Endpoint service associates to a GWLB ARN input and Endpoints associate to a list of Subnet ID inputs. The intent is to deploy these GWLB Endpoints across availability zone subnets for HA/resiliency and utilize the configured ENIs as next-hop for workload/spoke subnet default routes to steer all traffic to backend Cloud Connector clusters sitting behind GWLB.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
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
| [aws_vpc_endpoint.gwlb-vpce](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_vpc_endpoint_service.gwlb-vpce-service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint_service) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_global_tags"></a> [global\_tags](#input\_global\_tags) | Populate any custom user defined tags from a map | `map(string)` | `{}` | no |
| <a name="input_gwlb_arn"></a> [gwlb\_arn](#input\_gwlb\_arn) | ARN of GWLB for Endpoint Service to be assigned | `string` | n/a | yes |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | A prefix to associate to all the Cloud Connector module resources | `string` | `null` | no |
| <a name="input_resource_tag"></a> [resource\_tag](#input\_resource\_tag) | A tag to associate to all the Cloud Connector module resources | `string` | `null` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | List of Subnet ID to create GLWB Endpoints in | `list(string)` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | Cloud Connector VPC ID | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_gwlbe"></a> [gwlbe](#output\_gwlbe) | n/a |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->