# Zscaler Cloud Connector / AWS Network Infrastructure Module

This module has multi-purpose use and is leveraged by all other Zscaler Cloud Connector child modules in some capacity. All network infrastructure resources pertaining to connectivity dependencies for a successful Cloud Connector deployment in a private subnet are referenced here. Full list of resources can be found below, but in general this module will handle all VPC, IGW, Subnets, NAT Gateways, Elastic IP Addresses, and Route Table creations to build out a resilient AWS network architecture. Most resources also have "conditional create" capabilities where, by default, they will all be created unless instructed not to with various "byo" variables. Use cases are documented in more detail in each description in variables.tf as well as the terraform.tfvars example file for all non-base deployment types (ie: cc_gwlb, cc_ha, etc.).

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
| [aws_eip.eip](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_internet_gateway.igw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_nat_gateway.ngw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway) | resource |
| [aws_route_table.cc_rt](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.public_rt](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.route53_rt](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.workload_rt](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table_association.cc_rt_asssociation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.public_rt_association](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.route53_rt_asssociation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.workload_rt_association](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_subnet.cc_subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.public_subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.route53_subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.workload_subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_internet_gateway.igw_selected](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/internet_gateway) | data source |
| [aws_nat_gateway.ngw_selected](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/nat_gateway) | data source |
| [aws_subnet.cc_subnet_selected](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |
| [aws_vpc.vpc_selected](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_az_count"></a> [az\_count](#input\_az\_count) | Default number of subnets to create based on availability zone input | `number` | `2` | no |
| <a name="input_base_only"></a> [base\_only](#input\_base\_only) | Default is falase. Only applicable for base deployment type resulting in workload and bastion hosts, but no Cloud Connector resources. Setting this to true will point workload route able to nat\_gateway\_id | `bool` | `false` | no |
| <a name="input_byo_igw"></a> [byo\_igw](#input\_byo\_igw) | Bring your own AWS VPC for Cloud Connector | `bool` | `false` | no |
| <a name="input_byo_igw_id"></a> [byo\_igw\_id](#input\_byo\_igw\_id) | User provided existing AWS Internet Gateway ID | `string` | `null` | no |
| <a name="input_byo_ngw"></a> [byo\_ngw](#input\_byo\_ngw) | Bring your own AWS NAT Gateway(s) Cloud Connector | `bool` | `false` | no |
| <a name="input_byo_ngw_ids"></a> [byo\_ngw\_ids](#input\_byo\_ngw\_ids) | User provided existing AWS NAT Gateway IDs | `list(string)` | `null` | no |
| <a name="input_byo_subnet_ids"></a> [byo\_subnet\_ids](#input\_byo\_subnet\_ids) | User provided existing AWS Subnet IDs | `list(string)` | `null` | no |
| <a name="input_byo_subnets"></a> [byo\_subnets](#input\_byo\_subnets) | Bring your own AWS Subnets for Cloud Connector | `bool` | `false` | no |
| <a name="input_byo_vpc"></a> [byo\_vpc](#input\_byo\_vpc) | Bring your own AWS VPC for Cloud Connector | `bool` | `false` | no |
| <a name="input_byo_vpc_id"></a> [byo\_vpc\_id](#input\_byo\_vpc\_id) | User provided existing AWS VPC ID | `string` | `null` | no |
| <a name="input_cc_service_enis"></a> [cc\_service\_enis](#input\_cc\_service\_enis) | List of Cloud Connector Service ENIs for use in private workload and/or Route 53 subnet route tables with HA/non-GWLB deployments. Utilized if var.gwlb\_enabled is set to false | `list(string)` | <pre>[<br>  ""<br>]</pre> | no |
| <a name="input_cc_subnets"></a> [cc\_subnets](#input\_cc\_subnets) | Cloud Connector Subnets to create in VPC. This is only required if you want to override the default subnets that this code creates via vpc\_cidr variable. | `list(string)` | `null` | no |
| <a name="input_global_tags"></a> [global\_tags](#input\_global\_tags) | Populate any custom user defined tags from a map | `map(string)` | `{}` | no |
| <a name="input_gwlb_enabled"></a> [gwlb\_enabled](#input\_gwlb\_enabled) | Default is false. Workload/Route 53 subnet Route Tables will point to network\_interface\_id via var.cc\_service\_enis. If true, Route Tables will point to vpc\_endpoint\_id via var.gwlb\_endpoint\_ids input. | `bool` | `false` | no |
| <a name="input_gwlb_endpoint_ids"></a> [gwlb\_endpoint\_ids](#input\_gwlb\_endpoint\_ids) | List of GWLB Endpoint IDs for use in private workload and/or Route 53 subnet route tables with GWLB deployments. Utilized if var.gwlb\_enabled is set to true | `list(string)` | <pre>[<br>  ""<br>]</pre> | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | A prefix to associate to all the network module resources | `string` | `null` | no |
| <a name="input_public_subnets"></a> [public\_subnets](#input\_public\_subnets) | Public/NAT GW Subnets to create in VPC. This is only required if you want to override the default subnets that this code creates via vpc\_cidr variable. | `list(string)` | `null` | no |
| <a name="input_resource_tag"></a> [resource\_tag](#input\_resource\_tag) | A tag to associate to all the network module resources | `string` | `null` | no |
| <a name="input_route53_subnets"></a> [route53\_subnets](#input\_route53\_subnets) | Route 53 Outbound Endpoint Subnets to create in VPC. This is only required if you want to override the default subnets that this code creates via vpc\_cidr variable. | `list(string)` | `null` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | VPC IP CIDR Range. All subnet resources that might get created (public, workload, cloud connector) are derived from this /16 CIDR. If you require creating a VPC smaller than /16, you may need to explicitly define all other subnets via public\_subnets, workload\_subnets, cc\_subnets, and route53\_subnets variables | `string` | `"10.1.0.0/16"` | no |
| <a name="input_workloads_enabled"></a> [workloads\_enabled](#input\_workloads\_enabled) | Configure Workload Subnets, Route Tables, and associations if set to true | `bool` | `false` | no |
| <a name="input_workloads_subnets"></a> [workloads\_subnets](#input\_workloads\_subnets) | Workload Subnets to create in VPC. This is only required if you want to override the default subnets that this code creates via vpc\_cidr variable. | `list(string)` | `null` | no |
| <a name="input_zpa_enabled"></a> [zpa\_enabled](#input\_zpa\_enabled) | Configure Route 53 Subnets, Route Tables, and Resolvers for ZPA DNS redirection | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cc_subnet_ids"></a> [cc\_subnet\_ids](#output\_cc\_subnet\_ids) | Cloud Connector Subnet ID |
| <a name="output_nat_gateway_ips"></a> [nat\_gateway\_ips](#output\_nat\_gateway\_ips) | NAT Gateway Public IP |
| <a name="output_public_subnet_ids"></a> [public\_subnet\_ids](#output\_public\_subnet\_ids) | Public Subnet ID |
| <a name="output_route53_subnet_ids"></a> [route53\_subnet\_ids](#output\_route53\_subnet\_ids) | Route 53 Subnet ID |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | VPC ID |
| <a name="output_workload_route_table_ids"></a> [workload\_route\_table\_ids](#output\_workload\_route\_table\_ids) | Workloads Route Table ID |
| <a name="output_workload_subnet_ids"></a> [workload\_subnet\_ids](#output\_workload\_subnet\_ids) | Workloads Subnet ID |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
