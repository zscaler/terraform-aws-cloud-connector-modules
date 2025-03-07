# Zscaler Cloud Connector / AWS EC2 Instance (Cloud Connector) Module

This module creates all AWS EC2 instance and network interface resources needed to deploy Cloud Connector appliances.


## Subscribe to the AWS Marketplace

Subscribe and accept terms of using Zscaler Cloud Connector image at [this link](https://aws.amazon.com/marketplace/pp/prodview-cvzx4oiv7oljm). For China marketplace deployments, use [this link](https://awsmarketplace.amazonaws.cn/marketplace/pp/prodview-d2em5t67apisy).

| AWS Cloud                  | Product Code              |  Version                              |
|:--------------------------:|:-------------------------:|:-------------------------------------:|
| aws (Commercial)           | 2l8tfysndbav4tv2nfjwak3cu | ZS6.1.26.1 (Latest - as of Aug, 2024) |
| aws-us-gov (US Government) | 2l8tfysndbav4tv2nfjwak3cu | ZS6.1.26.1 (Latest - as of Aug, 2024) |
| aws-cn (China)             | axnpwhsb4facossmbm1h9yad6 | 24.3.1 (Latest - as of Aug, 2024)     |

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13.7, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.32 |
| <a name="requirement_local"></a> [local](#requirement\_local) | >= 2.2.0, < 2.6 |
| <a name="requirement_null"></a> [null](#requirement\_null) | ~> 3.1, < 3.3 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.32 |
| <a name="provider_null"></a> [null](#provider\_null) | ~> 3.1, < 3.3 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_instance.cc_vm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_network_interface.cc_vm_nic_index_0](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_interface) | resource |
| [aws_network_interface.cc_vm_nic_index_1](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_interface) | resource |
| [aws_network_interface.cc_vm_nic_index_2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_interface) | resource |
| [aws_network_interface.cc_vm_nic_index_3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_interface) | resource |
| [aws_network_interface.cc_vm_nic_index_4](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_interface) | resource |
| [aws_network_interface.cc_vm_nic_index_5](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_interface) | resource |
| [null_resource.error_checker](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [aws_ebs_default_kms_key.current_kms_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ebs_default_kms_key) | data source |
| [aws_kms_alias.current_kms_arn](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/kms_alias) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_mgmt_security_group_ids"></a> [additional\_mgmt\_security\_group\_ids](#input\_additional\_mgmt\_security\_group\_ids) | Optional additional Cloud Connector EC2 Instance management security group ids to be attached to the to the management interface | `list(string)` | `[]` | no |
| <a name="input_ami_id"></a> [ami\_id](#input\_ami\_id) | AMI ID(s) to be used for deploying Cloud Connector appliances. Ideally all VMs should be on the same AMI ID as templates always pull the latest from AWS Marketplace. This variable is provided if a customer desires to override/retain an old ami for existing deployments rather than upgrading and forcing a replacement. It is also inputted as a list to facilitate if a customer desired to manually upgrade select CCs deployed based on the cc\_count index | `list(string)` | n/a | yes |
| <a name="input_byo_kms_key_alias"></a> [byo\_kms\_key\_alias](#input\_byo\_kms\_key\_alias) | Requires var.ebs\_encryption\_enabled to be true. Set to null by default which is the AWS default managed/master key. Set as 'alias/<key-alias>' to use a custom KMS key | `string` | `null` | no |
| <a name="input_cc_count"></a> [cc\_count](#input\_cc\_count) | Default number of Cloud Connector appliances to create | `number` | `1` | no |
| <a name="input_cc_instance_size"></a> [cc\_instance\_size](#input\_cc\_instance\_size) | Cloud Connector Instance size. Determined by and needs to match the Cloud Connector Portal provisioning template configuration | `string` | `"small"` | no |
| <a name="input_ccvm_instance_type"></a> [ccvm\_instance\_type](#input\_ccvm\_instance\_type) | Cloud Connector Instance Type | `string` | `"m6i.large"` | no |
| <a name="input_ebs_encryption_enabled"></a> [ebs\_encryption\_enabled](#input\_ebs\_encryption\_enabled) | true/false whether to enable EBS encryption on the root volume. Default is true | `bool` | `true` | no |
| <a name="input_ebs_volume_type"></a> [ebs\_volume\_type](#input\_ebs\_volume\_type) | (Optional) Type of volume. Valid values include standard, gp2, gp3, io1, io2, sc1, or st1. Defaults to gp3 | `string` | `"gp3"` | no |
| <a name="input_global_tags"></a> [global\_tags](#input\_global\_tags) | Populate any custom user defined tags from a map | `map(string)` | `{}` | no |
| <a name="input_hostname_type"></a> [hostname\_type](#input\_hostname\_type) | Type of hostname for Amazon EC2 instances | `string` | `"resource-name"` | no |
| <a name="input_iam_instance_profile"></a> [iam\_instance\_profile](#input\_iam\_instance\_profile) | IAM instance profile ID assigned to Cloud Connector | `list(string)` | n/a | yes |
| <a name="input_imdsv2_enabled"></a> [imdsv2\_enabled](#input\_imdsv2\_enabled) | true/false whether to force IMDSv2 only for instance bring up. Default is true | `bool` | `true` | no |
| <a name="input_instance_key"></a> [instance\_key](#input\_instance\_key) | SSH Key for instances | `string` | n/a | yes |
| <a name="input_mgmt_security_group_id"></a> [mgmt\_security\_group\_id](#input\_mgmt\_security\_group\_id) | Cloud Connector EC2 Instance management security group id | `list(string)` | n/a | yes |
| <a name="input_mgmt_subnet_id"></a> [mgmt\_subnet\_id](#input\_mgmt\_subnet\_id) | Cloud Connector EC2 Instance management subnet id | `list(string)` | n/a | yes |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | A prefix to associate to all the Cloud Connector module resources | `string` | `null` | no |
| <a name="input_resource_name_dns_a_record_enabled"></a> [resource\_name\_dns\_a\_record\_enabled](#input\_resource\_name\_dns\_a\_record\_enabled) | Indicates whether to respond to DNS queries for instance hostnames with DNS A records. Default is false | `bool` | `false` | no |
| <a name="input_resource_tag"></a> [resource\_tag](#input\_resource\_tag) | A tag to associate to all the Cloud Connector module resources | `string` | `null` | no |
| <a name="input_service_security_group_id"></a> [service\_security\_group\_id](#input\_service\_security\_group\_id) | Cloud Connector EC2 Instance service security group id | `list(string)` | n/a | yes |
| <a name="input_service_subnet_id"></a> [service\_subnet\_id](#input\_service\_subnet\_id) | Cloud Connector EC2 Instance service subnet id | `list(string)` | n/a | yes |
| <a name="input_user_data"></a> [user\_data](#input\_user\_data) | Cloud Init data | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_availability_zone"></a> [availability\_zone](#output\_availability\_zone) | Instance Availability Zone |
| <a name="output_forwarding_eni"></a> [forwarding\_eni](#output\_forwarding\_eni) | Instance Device Index 0 Network ID |
| <a name="output_forwarding_ip"></a> [forwarding\_ip](#output\_forwarding\_ip) | Instance Forwarding/Service IP |
| <a name="output_id"></a> [id](#output\_id) | EC2 Instance ID |
| <a name="output_management_eni"></a> [management\_eni](#output\_management\_eni) | Instance Device Index 1 Network ID |
| <a name="output_management_ip"></a> [management\_ip](#output\_management\_ip) | Instance Device Index 1 Private IP |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
