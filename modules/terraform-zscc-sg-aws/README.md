# Zscaler Cloud Connector / AWS Security Groups Module

This module creates Security Rules and Groups resources required for successful Cloud Connector deployments. As part of Zscaler provided deployment templates most resources have conditional create options leveraged "byo" variables should a customer want to leverage the module outputs with data reference to resources that may already exist in their AWS environment. Security Group rules are populated per Zscaler connectivity requirements and minimum access best practices. Please refer to [Zscaler Workload Communications (Cloud/Branch Connector)](https://config.zscaler.com/zscaler.net/cloud-branch-connector).

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
| [aws_security_group.cc_mgmt_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.cc_service_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.outbound_endpoint_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_vpc_security_group_egress_rule.egress_cc_mgmt_pkg_repo](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_egress_rule.egress_cc_mgmt_tcp_12002](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_egress_rule.egress_cc_mgmt_tcp_443](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_egress_rule.egress_cc_mgmt_udp_123](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_egress_rule.egress_cc_mgmt_udp_53](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_egress_rule.egress_cc_service_all](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_egress_rule.egress_cc_service_geneve](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_egress_rule.egress_cc_service_tcp_443](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_egress_rule.egress_cc_service_udp_123](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_egress_rule.egress_cc_service_udp_443](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_egress_rule.egress_cc_service_udp_53](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_egress_rule.egress_outbound_endpoint_tcp_all](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_egress_rule.egress_outbound_endpoint_udp_all](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.cc_mgmt_ingress_ssh](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.ingress_cc_service_all](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.ingress_cc_service_geneve](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.ingress_cc_service_health_check](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.ingress_cc_service_https_local](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.ingress_outbound_endpoint_tcp_all](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.ingress_outbound_endpoint_udp_all](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_security_group.cc_mgmt_sg_selected](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/security_group) | data source |
| [aws_security_group.cc_service_sg_selected](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/security_group) | data source |
| [aws_security_group.outbound_endpoint_sg_selected](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/security_group) | data source |
| [aws_vpc.selected](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_all_ports_egress_enabled"></a> [all\_ports\_egress\_enabled](#input\_all\_ports\_egress\_enabled) | Default is true which creates an egress rule permitting the CC service interface to forward direct traffic on all ports and protocols. If false, the rule is not created. Value ignored if not creating a security group | `bool` | `true` | no |
| <a name="input_byo_mgmt_security_group_id"></a> [byo\_mgmt\_security\_group\_id](#input\_byo\_mgmt\_security\_group\_id) | Management Security Group ID for Cloud Connector association | `list(string)` | `null` | no |
| <a name="input_byo_route53_resolver_outbound_endpoint_group_id"></a> [byo\_route53\_resolver\_outbound\_endpoint\_group\_id](#input\_byo\_route53\_resolver\_outbound\_endpoint\_group\_id) | Route53 Resolver Outbound Endpoint Security Group ID | `list(string)` | `null` | no |
| <a name="input_byo_security_group"></a> [byo\_security\_group](#input\_byo\_security\_group) | Bring your own Security Group for Cloud Connector. Setting this variable to true will effectively instruct this module to not create any resources and only reference data resources from values provided in byo\_mgmt\_security\_group\_id and byo\_service\_security\_group\_id | `bool` | `false` | no |
| <a name="input_byo_service_security_group_id"></a> [byo\_service\_security\_group\_id](#input\_byo\_service\_security\_group\_id) | Service Security Group ID for Cloud Connector association | `list(string)` | `null` | no |
| <a name="input_global_tags"></a> [global\_tags](#input\_global\_tags) | Populate any custom user defined tags from a map | `map(string)` | `{}` | no |
| <a name="input_gwlb_enabled"></a> [gwlb\_enabled](#input\_gwlb\_enabled) | Default is true which creates ingress/egress rules only for GENEVE traffic. If false, these rules are replaced with an allow all ports/protocols ingress. Value ignored if not creating a security group | `bool` | `true` | no |
| <a name="input_http_probe_port"></a> [http\_probe\_port](#input\_http\_probe\_port) | Port number for Cloud Connector cloud init to enable listener port for HTTP probe from GWLB Target Group | `number` | `50000` | no |
| <a name="input_mgmt_ssh_enabled"></a> [mgmt\_ssh\_enabled](#input\_mgmt\_ssh\_enabled) | Default is true which creates an ingress rule permitting SSH traffic from the local VPC to the CC management interface. If false, the rule is not created. Value ignored if not creating a security group | `bool` | `true` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | A prefix to associate to all the Cloud Connector Security Group module resources | `string` | `null` | no |
| <a name="input_resource_tag"></a> [resource\_tag](#input\_resource\_tag) | A tag to associate to all the Cloud Connector Security Group module resources | `string` | `null` | no |
| <a name="input_sg_count"></a> [sg\_count](#input\_sg\_count) | Default number of security groups to create | `number` | `1` | no |
| <a name="input_support_access_enabled"></a> [support\_access\_enabled](#input\_support\_access\_enabled) | If Network Security Group is being configured, enable a specific outbound rule for Cloud Connector to be able to establish connectivity for Zscaler support access. Default is true | `bool` | `true` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | Cloud Connector VPC ID | `string` | n/a | yes |
| <a name="input_zpa_enabled"></a> [zpa\_enabled](#input\_zpa\_enabled) | Configure Route 53 Security Group for ZPA DNS redirection | `bool` | `false` | no |
| <a name="input_zssupport_server"></a> [zssupport\_server](#input\_zssupport\_server) | destination IP address of Zscaler Support access server. IP resolution of remotesupport.<zscaler\_customer\_cloud>.net | `string` | `"199.168.148.101/32"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_mgmt_security_group_arn"></a> [mgmt\_security\_group\_arn](#output\_mgmt\_security\_group\_arn) | Instance Management Security Group ARN |
| <a name="output_mgmt_security_group_id"></a> [mgmt\_security\_group\_id](#output\_mgmt\_security\_group\_id) | Instance Management Security Group ID |
| <a name="output_outbound_endpoint_security_group_arn"></a> [outbound\_endpoint\_security\_group\_arn](#output\_outbound\_endpoint\_security\_group\_arn) | Route53 DNS Resolver Outbound Endpoint Security Group ARN |
| <a name="output_outbound_endpoint_security_group_id"></a> [outbound\_endpoint\_security\_group\_id](#output\_outbound\_endpoint\_security\_group\_id) | Route53 DNS Resolver Outbound Endpoint Security Group ID |
| <a name="output_service_security_group_arn"></a> [service\_security\_group\_arn](#output\_service\_security\_group\_arn) | Instance Service Security Group ARN |
| <a name="output_service_security_group_id"></a> [service\_security\_group\_id](#output\_service\_security\_group\_id) | Instance Service Security Group ID |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
