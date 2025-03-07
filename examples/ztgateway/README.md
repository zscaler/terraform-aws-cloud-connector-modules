# Zscaler Custom Deployment Template with Zero Trust Gateway (ztgateway)

This deployment type is intended for brownfield/production purposes. By default, it will deploy Zero Trust Endpoints to either a new or pre-existing VPC and Subnets to integrate with a Zscaler Zero Trust Gateway. Full set of resources provisioned listed below.

## How to deploy:

### Option 1 (guided):
From the examples directory, run the zsec bash script that walks to all required inputs.
- ./zsec up
- enter "greenfield"
- enter "ztgateway"
- follow the remainder of the authentication and configuration input prompts.
- script will detect client operating system and download/run a specific version of terraform in a temporary bin directory
- inputs will be validated and terraform init/apply will automatically exectute.
- verify all resources that will be created/modified and enter "yes" to confirm

### Option 2 (manual):
Modify/populate any required variable input values in ztgateway/terraform.tfvars file and save.

From ztgateway directory execute:
- terraform init
- terraform apply

## How to destroy:

### Option 1 (guided):
From the examples directory, run the zsec bash script that walks to all required inputs.
- ./zsec destroy

### Option 2 (manual):
From ztgateway directory execute:
- terraform destroy

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13.7, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.32.0, <= 5.49.0 |
| <a name="requirement_local"></a> [local](#requirement\_local) | ~> 2.5.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | ~> 3.2.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.6.0 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | ~> 4.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_local"></a> [local](#provider\_local) | ~> 2.5.0 |
| <a name="provider_random"></a> [random](#provider\_random) | ~> 3.6.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_gwlb_endpoint"></a> [gwlb\_endpoint](#module\_gwlb\_endpoint) | ../../modules/terraform-zscc-gwlbendpoint-aws | n/a |
| <a name="module_network"></a> [network](#module\_network) | ../../modules/terraform-zscc-network-aws | n/a |

## Resources

| Name | Type |
|------|------|
| [local_file.testbed](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [random_string.suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | The AWS region. | `string` | `"us-west-2"` | no |
| <a name="input_az_count"></a> [az\_count](#input\_az\_count) | Default number of subnets to create based on availability zone | `number` | `1` | no |
| <a name="input_az_ids"></a> [az\_ids](#input\_az\_ids) | By default, this module does a lookup for all regional availability zones marked as available.<br/>If creating new Zscaler private subnets, it then automatically loops through in order of the returned list based on the variable az\_count.<br/>Providing each AWS Zone ID explicitly here will take precedence over var.az\_count.<br/><br/>Example: When deploying a greenfield ZT Gateway template in region us-east-1 and 2 AZs where you want to ensure that new subnets<br/>are created in use1-az1 and use1-az5, set this variable to:<br/>az\_ids = ["use1-az1" "use1-az5"]<br/><br/>Caution: This argument is not supported in all regions or partitions | `list(string)` | `null` | no |
| <a name="input_byo_endpoint_service_name"></a> [byo\_endpoint\_service\_name](#input\_byo\_endpoint\_service\_name) | Exising GWLB Endpoint Service name to associate GWLB Endpoints to. Example string format:  "com.amazonaws.vpce.<region>.<service id>" | `string` | `null` | no |
| <a name="input_byo_subnet_ids"></a> [byo\_subnet\_ids](#input\_byo\_subnet\_ids) | User provided existing AWS Subnet IDs | `list(string)` | `null` | no |
| <a name="input_byo_subnets"></a> [byo\_subnets](#input\_byo\_subnets) | Bring your own AWS Subnets for Cloud Connector | `bool` | `false` | no |
| <a name="input_byo_vpc"></a> [byo\_vpc](#input\_byo\_vpc) | Bring your own AWS VPC for Cloud Connector | `bool` | `false` | no |
| <a name="input_byo_vpc_id"></a> [byo\_vpc\_id](#input\_byo\_vpc\_id) | User provided existing AWS VPC ID | `string` | `null` | no |
| <a name="input_endpoint_subnets"></a> [endpoint\_subnets](#input\_endpoint\_subnets) | Zscaler Subnets to create in VPC. This is only required if you want to override the default subnets that this code creates via vpc\_cidr variable. | `list(string)` | `null` | no |
| <a name="input_exclude_igw"></a> [exclude\_igw](#input\_exclude\_igw) | By default, example templates require an Internet Gateway to either be created or already exist. Set this variable to true to ensure this module does not depend on either. Only recommended in niche customer environments where internet egresses through a private connection like Direct Connect or ZT Gateway Service deployments | `bool` | `false` | no |
| <a name="input_exclude_ngw"></a> [exclude\_ngw](#input\_exclude\_ngw) | By default, example templates require one or more NAT Gateway to either be created or already exist. Set this variable to true to ensure this module does not depend on either. Only recommended in niche customer environments where Cloud Connectors are deployed with Public IP Addresses or ZT Gateway Service deployments | `bool` | `true` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | The name prefix for all your resources | `string` | `"zscc"` | no |
| <a name="input_owner_tag"></a> [owner\_tag](#input\_owner\_tag) | populate custom owner tag attribute | `string` | `"zscc-admin"` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | VPC IP CIDR Range. All subnet resources that might get created (public, workload, Zscaler) are derived from this /16 CIDR. If you require creating a VPC smaller than /16, you may need to explicitly define all other subnets via public\_subnets, workload\_subnets, cc\_subnets, and route53\_subnets variables | `string` | `"10.1.0.0/16"` | no |
| <a name="input_zs_route_table_enabled"></a> [zs\_route\_table\_enabled](#input\_zs\_route\_table\_enabled) | For brownfield environments where VPC subnets already exist, set to false to not create a new route table to associate to Zscaler subnet(s). Default is true which means module will try to create new route tables | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_testbedconfig"></a> [testbedconfig](#output\_testbedconfig) | AWS Testbed results |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
