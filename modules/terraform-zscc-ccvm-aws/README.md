# Zscaler Cloud Connector / AWS EC2 Instance (Cloud Connector) Module

This module creates all AWS EC2 instance and network interface resources needed to deploy Cloud Connector appliances.

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
| [aws_instance.cc_vm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_network_interface.cc_vm_nic_index_1](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_interface) | resource |
| [aws_network_interface.cc_vm_nic_index_2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_interface) | resource |
| [aws_network_interface.cc_vm_nic_index_3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_interface) | resource |
| [aws_network_interface.cc_vm_nic_index_4](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_interface) | resource |
| [null_resource.error_checker](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [aws_ami.cloudconnector](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_network_interface.cc_vm_nic_index_1_eni](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/network_interface) | data source |
| [aws_network_interface.cc_vm_nic_index_2_eni](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/network_interface) | data source |
| [aws_network_interface.cc_vm_nic_index_3_eni](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/network_interface) | data source |
| [aws_network_interface.cc_vm_nic_index_4_eni](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/network_interface) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cc_count"></a> [cc\_count](#input\_cc\_count) | Default number of Cloud Connector appliances to create | `number` | `1` | no |
| <a name="input_cc_instance_size"></a> [cc\_instance\_size](#input\_cc\_instance\_size) | Cloud Connector Instance size. Determined by and needs to match  the Cloud Connector Portal provisioning template configuration | `string` | `"small"` | no |
| <a name="input_ccvm_instance_type"></a> [ccvm\_instance\_type](#input\_ccvm\_instance\_type) | Cloud Connector Instance Type | `string` | `"m5.large"` | no |
| <a name="input_global_tags"></a> [global\_tags](#input\_global\_tags) | Populate any custom user defined tags from a map | `map(string)` | `{}` | no |
| <a name="input_iam_instance_profile"></a> [iam\_instance\_profile](#input\_iam\_instance\_profile) | IAM instance profile ID assigned to Cloud Connector | `list(string)` | n/a | yes |
| <a name="input_instance_key"></a> [instance\_key](#input\_instance\_key) | SSH Key for instances | `string` | n/a | yes |
| <a name="input_mgmt_security_group_id"></a> [mgmt\_security\_group\_id](#input\_mgmt\_security\_group\_id) | Cloud Connector EC2 Instance management subnet id | `list(string)` | n/a | yes |
| <a name="input_mgmt_subnet_id"></a> [mgmt\_subnet\_id](#input\_mgmt\_subnet\_id) | Cloud Connector EC2 Instance management subnet id | `list(string)` | n/a | yes |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | A prefix to associate to all the Cloud Connector module resources | `string` | `null` | no |
| <a name="input_resource_tag"></a> [resource\_tag](#input\_resource\_tag) | A tag to associate to all the Cloud Connector module resources | `string` | `null` | no |
| <a name="input_service_security_group_id"></a> [service\_security\_group\_id](#input\_service\_security\_group\_id) | Cloud Connector EC2 Instance service subnet id | `list(string)` | n/a | yes |
| <a name="input_service_subnet_id"></a> [service\_subnet\_id](#input\_service\_subnet\_id) | Cloud Connector EC2 Instance service subnet id | `list(string)` | n/a | yes |
| <a name="input_user_data"></a> [user\_data](#input\_user\_data) | Cloud Init data | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_availability_zone"></a> [availability\_zone](#output\_availability\_zone) | Instance Availability Zone |
| <a name="output_cc_lrg_service_3_private_ip"></a> [cc\_lrg\_service\_3\_private\_ip](#output\_cc\_lrg\_service\_3\_private\_ip) | Instance Device Index 4 Private IP |
| <a name="output_cc_med_lrg_service_1_private_ip"></a> [cc\_med\_lrg\_service\_1\_private\_ip](#output\_cc\_med\_lrg\_service\_1\_private\_ip) | Instance Device Index 2 Private IP |
| <a name="output_cc_med_lrg_service_2_private_ip"></a> [cc\_med\_lrg\_service\_2\_private\_ip](#output\_cc\_med\_lrg\_service\_2\_private\_ip) | Instance Device Index 3 Private IP |
| <a name="output_cc_service_private_ip"></a> [cc\_service\_private\_ip](#output\_cc\_service\_private\_ip) | Instance Device Index 1 Private IP |
| <a name="output_id"></a> [id](#output\_id) | Instance ID |
| <a name="output_private_ip"></a> [private\_ip](#output\_private\_ip) | Instance Private IP |
| <a name="output_service_eni_1"></a> [service\_eni\_1](#output\_service\_eni\_1) | Instance Device Index 1 Network ID |
| <a name="output_service_eni_2"></a> [service\_eni\_2](#output\_service\_eni\_2) | Instance Device Index 2 Network ID |
| <a name="output_service_eni_3"></a> [service\_eni\_3](#output\_service\_eni\_3) | Instance Device Index 3 Network ID |
| <a name="output_service_eni_4"></a> [service\_eni\_4](#output\_service\_eni\_4) | Instance Device Index 4 Network ID |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
