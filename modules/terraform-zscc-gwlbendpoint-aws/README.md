# Zscaler Cloud Connector / AWS Gateway Load Balancer Endpoint and Endpoint Service Module

This module creates Gateway Load Balancer Endpoint (GWLBE) and VPC Endpoint Service for GWLB resources. Endpoint service associates to a GWLB ARN input and Endpoints associate to a list of Subnet ID inputs.

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
| [aws_vpc_endpoint_service.gwlb-vpce-service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/aws_vpc_endpoint_service) | resource |
| [aws_vpc_endpoint.gwlb-vpce](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/aws_vpc_endpoint) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="name_prefix"></a> [name\_prefix](#name\_prefix) | A prefix to associate to all the Cloud Connector module resources. | `string` | `null` | no |
| <a name="resource_tag"></a> [resource\_tag](#resource\_tag) | A tag to associate to all the Cloud Connector module resources. | `string` | `null` | no |
| <a name="vpc_id"></a> [vpc\_id](#vpc\_id) | Cloud Connector VPC ID. | `string` | `null` | yes |
| <a name="cc_subnet_ids"></a> [cc\_subnet\_ids](#cc\_subnet\_ids) | List of Subnet IDs to create GWLB in. | `list(string)` | `[]` | yes |
| <a name="global_tags"></a> [global\_tags](#global\_tags) | Populate any custom user defined tags from a map.<br>Example for defining tag Keys and Values:<pre>locals { <br>global_tags = {<br>  Owner = var.owner_tag <br>  ManagedBy = "terraform"<br>}</pre> | `map(string)` | `[]` | no |
| <a name="gwlb_arn"></a> [gwlb\_arn](#gwlb\_arn) | ARN of GWLB for Endpoint Service to be assigned. | `string` | `[]` | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="gwlbe"></a> [gwlbe](#gwlbe) | ID of the aws_vpc_endpoint (GLWB Endpoint) resource |
