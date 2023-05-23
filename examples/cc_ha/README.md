# Zscaler "cc_ha" deployment type (deprecated)

- **Note** This is only available as reference for legacy users. Zscaler's recommended deployment method is Gateway Load Balancer (GWLB), which distributes traffic across multiple Cloud Connectors and achieves high availability. Please refer to [**Custom Deployment template with GWLB**](../cc_gwlb).

This deployment type is intended for brownfield/production purposes. By default, it will create 1 new VPC with 2 public subnets and 2 Cloud Connector private subnets; 1 IGW; 2 NAT Gateways; 2 Cloud Connector VMs (2 per subnet/AZ) routing to the NAT Gateway in their same AZ; generates local key pair .pem file for ssh access; BYO ability to use existing resources (VPC, subnets, IGW, NAT Gateways), and toggle ZPA/R53 and Lambda HA failover features; generates local key pair .pem file for ssh access; Gateway Load Balancer auto registers service IPs to target group with health checks; VPC Endpoint Service; 2 GWLB Endpoints (1 in each Cloud Connector subnet)<br>

*** For production deployments and better scaling/resliency, we highly advise leveraging Gateway Load Balancer (GWLB) rather than HA with Lambda failover. You can refer to deployment type "cc_gwlb" for this reference architecture.

## How to deploy:

### Option 1 (guided):
Optional - First edit examples/cc_ha/terraform.tfvars with any "byo" variable values that already exist in your environment and save the file.
From the examples directory, run the zsec bash script that walks to all required inputs.
- ./zsec up
- enter "brownfield"
- enter "cc_ha"
- follow the remainder of the authentication and configuration input prompts.
- script will detect client operating system and download/run a specific version of terraform in a temporary bin directory
- inputs will be validated and terraform init/apply will automatically exectute.
- verify all resources that will be created/modified and enter "yes" to confirm

### Option 2 (manual):
Modify/populate any required variable input values in examples/cc_ha/terraform.tfvars file and save.

From cc_ha directory execute:
- terraform init
- terraform apply

## How to destroy:

### Option 1 (guided):
From the examples directory, run the zsec bash script that walks to all required inputs.
- ./zsec destroy

### Option 2 (manual):
From cc_ha directory execute:
- terraform destroy

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13.7, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 4.59.0 |
| <a name="requirement_local"></a> [local](#requirement\_local) | ~> 2.2.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | ~> 3.1.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.3.0 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | ~> 3.4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 4.59.0 |
| <a name="provider_local"></a> [local](#provider\_local) | ~> 2.2.0 |
| <a name="provider_null"></a> [null](#provider\_null) | ~> 3.1.0 |
| <a name="provider_random"></a> [random](#provider\_random) | ~> 3.3.0 |
| <a name="provider_tls"></a> [tls](#provider\_tls) | ~> 3.4.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_cc_iam"></a> [cc\_iam](#module\_cc\_iam) | ../../modules/terraform-zscc-iam-aws | n/a |
| <a name="module_cc_lambda"></a> [cc\_lambda](#module\_cc\_lambda) | ../../modules/terraform-zscc-lambda-aws | n/a |
| <a name="module_cc_sg"></a> [cc\_sg](#module\_cc\_sg) | ../../modules/terraform-zscc-sg-aws | n/a |
| <a name="module_cc_vm"></a> [cc\_vm](#module\_cc\_vm) | ../../modules/terraform-zscc-ccvm-aws | n/a |
| <a name="module_network"></a> [network](#module\_network) | ../../modules/terraform-zscc-network-aws | n/a |
| <a name="module_route53"></a> [route53](#module\_route53) | ../../modules/terraform-zscc-route53-aws | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_key_pair.deployer](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair) | resource |
| [local_file.private_key](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.testbed](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.user_data_file](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [null_resource.cc_error_checker](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [random_string.suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [tls_private_key.key](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [aws_ami.cloudconnector](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ami_id"></a> [ami\_id](#input\_ami\_id) | AMI ID(s) to be used for deploying Cloud Connector appliances. Ideally all VMs should be on the same AMI ID as templates always pull the latest from AWS Marketplace. This variable is provided if a customer desires to override/retain an old ami for existing deployments rather than upgrading and forcing a replacement. It is also inputted as a list to facilitate if a customer desired to manually upgrade select CCs deployed based on the cc\_count index | `list(string)` | <pre>[<br>  ""<br>]</pre> | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | The AWS region. | `string` | `"us-west-2"` | no |
| <a name="input_az_count"></a> [az\_count](#input\_az\_count) | Default number of subnets to create based on availability zone | `number` | `2` | no |
| <a name="input_byo_iam"></a> [byo\_iam](#input\_byo\_iam) | Bring your own IAM Instance Profile for Cloud Connector | `bool` | `false` | no |
| <a name="input_byo_iam_instance_profile_id"></a> [byo\_iam\_instance\_profile\_id](#input\_byo\_iam\_instance\_profile\_id) | IAM Instance Profile ID for Cloud Connector association | `list(string)` | `null` | no |
| <a name="input_byo_igw"></a> [byo\_igw](#input\_byo\_igw) | Bring your own AWS VPC for Cloud Connector | `bool` | `false` | no |
| <a name="input_byo_igw_id"></a> [byo\_igw\_id](#input\_byo\_igw\_id) | User provided existing AWS Internet Gateway ID | `string` | `null` | no |
| <a name="input_byo_mgmt_security_group_id"></a> [byo\_mgmt\_security\_group\_id](#input\_byo\_mgmt\_security\_group\_id) | Management Security Group ID for Cloud Connector association | `list(string)` | `null` | no |
| <a name="input_byo_ngw"></a> [byo\_ngw](#input\_byo\_ngw) | Bring your own AWS NAT Gateway(s) Cloud Connector | `bool` | `false` | no |
| <a name="input_byo_ngw_ids"></a> [byo\_ngw\_ids](#input\_byo\_ngw\_ids) | User provided existing AWS NAT Gateway IDs | `list(string)` | `null` | no |
| <a name="input_byo_security_group"></a> [byo\_security\_group](#input\_byo\_security\_group) | Bring your own Security Group for Cloud Connector | `bool` | `false` | no |
| <a name="input_byo_service_security_group_id"></a> [byo\_service\_security\_group\_id](#input\_byo\_service\_security\_group\_id) | Service Security Group ID for Cloud Connector association | `list(string)` | `null` | no |
| <a name="input_byo_subnet_ids"></a> [byo\_subnet\_ids](#input\_byo\_subnet\_ids) | User provided existing AWS Subnet IDs | `list(string)` | `null` | no |
| <a name="input_byo_subnets"></a> [byo\_subnets](#input\_byo\_subnets) | Bring your own AWS Subnets for Cloud Connector | `bool` | `false` | no |
| <a name="input_byo_vpc"></a> [byo\_vpc](#input\_byo\_vpc) | Bring your own AWS VPC for Cloud Connector | `bool` | `false` | no |
| <a name="input_byo_vpc_id"></a> [byo\_vpc\_id](#input\_byo\_vpc\_id) | User provided existing AWS VPC ID | `string` | `null` | no |
| <a name="input_cc_callhome_enabled"></a> [cc\_callhome\_enabled](#input\_cc\_callhome\_enabled) | determine whether or not to create the cc-callhome-policy IAM Policy and attach it to the CC IAM Role | `bool` | `true` | no |
| <a name="input_cc_count"></a> [cc\_count](#input\_cc\_count) | Default number of Cloud Connector appliances to create | `number` | `2` | no |
| <a name="input_cc_instance_size"></a> [cc\_instance\_size](#input\_cc\_instance\_size) | Cloud Connector Instance size. Determined by and needs to match  the Cloud Connector Portal provisioning template configuration | `string` | `"small"` | no |
| <a name="input_cc_subnets"></a> [cc\_subnets](#input\_cc\_subnets) | Cloud Connector Subnets to create in VPC. This is only required if you want to override the default subnets that this code creates via vpc\_cidr variable. | `list(string)` | `null` | no |
| <a name="input_cc_vm_prov_url"></a> [cc\_vm\_prov\_url](#input\_cc\_vm\_prov\_url) | Zscaler Cloud Connector Provisioning URL | `string` | n/a | yes |
| <a name="input_ccvm_instance_type"></a> [ccvm\_instance\_type](#input\_ccvm\_instance\_type) | Cloud Connector Instance Type | `string` | `"m5.large"` | no |
| <a name="input_domain_names"></a> [domain\_names](#input\_domain\_names) | Domain names fqdn/wildcard to have Route 53 redirect DNS requests to Cloud Connector for ZPA. Refer to terraform.tfvars ZPA/Route 53 specific variables | `map(any)` | `{}` | no |
| <a name="input_gwlb_enabled"></a> [gwlb\_enabled](#input\_gwlb\_enabled) | Default is false. Workload/Route 53 subnet Route Tables will point to network\_interface\_id via var.cc\_service\_enis. If true, Route Tables will point to vpc\_endpoint\_id via var.gwlb\_endpoint\_ids input. | `bool` | `false` | no |
| <a name="input_http_probe_port"></a> [http\_probe\_port](#input\_http\_probe\_port) | Port number for Cloud Connector cloud init to enable listener port for HTTP probe from GWLB Target Group | `number` | `50000` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | The name prefix for all your resources | `string` | `"zscc"` | no |
| <a name="input_owner_tag"></a> [owner\_tag](#input\_owner\_tag) | populate custom owner tag attribute | `string` | `"zscc-admin"` | no |
| <a name="input_public_subnets"></a> [public\_subnets](#input\_public\_subnets) | Public/NAT GW Subnets to create in VPC. This is only required if you want to override the default subnets that this code creates via vpc\_cidr variable. | `list(string)` | `null` | no |
| <a name="input_reuse_iam"></a> [reuse\_iam](#input\_reuse\_iam) | Specifies whether the SG module should create 1:1 IAM per instance or 1 IAM for all instances | `bool` | `false` | no |
| <a name="input_reuse_security_group"></a> [reuse\_security\_group](#input\_reuse\_security\_group) | Specifies whether the SG module should create 1:1 security groups per instance or 1 security group for all instances | `bool` | `false` | no |
| <a name="input_route53_subnets"></a> [route53\_subnets](#input\_route53\_subnets) | Route 53 Outbound Endpoint Subnets to create in VPC. This is only required if you want to override the default subnets that this code creates via vpc\_cidr variable. | `list(string)` | `null` | no |
| <a name="input_secret_name"></a> [secret\_name](#input\_secret\_name) | AWS Secrets Manager Secret Name for Cloud Connector provisioning | `string` | n/a | yes |
| <a name="input_target_address"></a> [target\_address](#input\_target\_address) | Route 53 DNS queries will be forwarded to these Zscaler Global VIP addresses | `list(string)` | <pre>[<br>  "185.46.212.88",<br>  "185.46.212.89"<br>]</pre> | no |
| <a name="input_tls_key_algorithm"></a> [tls\_key\_algorithm](#input\_tls\_key\_algorithm) | algorithm for tls\_private\_key resource | `string` | `"RSA"` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | VPC IP CIDR Range. All subnet resources that might get created (public, workload, cloud connector) are derived from this /16 CIDR. If you require creating a VPC smaller than /16, you may need to explicitly define all other subnets via public\_subnets, workload\_subnets, cc\_subnets, and route53\_subnets variables | `string` | `"10.1.0.0/16"` | no |
| <a name="input_workload_route_table_ids_to_cc_1"></a> [workload\_route\_table\_ids\_to\_cc\_1](#input\_workload\_route\_table\_ids\_to\_cc\_1) | User provided existing AWS Route Table IDs sending to Cloud Connector 1 in pair | `list(string)` | `null` | no |
| <a name="input_workload_route_table_ids_to_cc_2"></a> [workload\_route\_table\_ids\_to\_cc\_2](#input\_workload\_route\_table\_ids\_to\_cc\_2) | User provided existing AWS Route Table IDs sending to Cloud Connector 2 in pair | `list(string)` | `null` | no |
| <a name="input_workloads_enabled"></a> [workloads\_enabled](#input\_workloads\_enabled) | Configure Workload Subnets, Route Tables, and associations if set to true | `bool` | `false` | no |
| <a name="input_zpa_enabled"></a> [zpa\_enabled](#input\_zpa\_enabled) | Configure Route 53 Subnets, Route Tables, and Resolvers for ZPA DNS redirection | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_testbedconfig"></a> [testbedconfig](#output\_testbedconfig) | AWS Testbed results |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
