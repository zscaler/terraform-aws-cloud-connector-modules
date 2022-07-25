# Zscaler "Base_2cc_zpa" deployment type

This deployment type is intended for greenfield/pov/lab purposes. It will deploy a fully functioning sandbox environment in a new VPC with test workload VMs. Full set of resources provisioned listed below, but this will effectively create all network infrastructure dependencies for an AWS environment. Everything from "Base_1cc" deployment type (Creates 1 new VPC with 1 public subnet and 1 private/workload subnet; 1 IGW; 1 NAT Gateway; 1 Centos server workload in the private subnet routing to NAT Gateway; 1 Bastion Host in the public subnet assigned an Elastic IP and routing to the IGW; generates local key pair .pem file for ssh access; Creates 1 Cloud Connector private subnet; 1 Cloud Connector VM routing to NAT Gateway; workload private subnet route repointed to service ENI of Cloud Connector; Creates a second Cloud Connector in a new subnet/Availability Zone wwith Lambda configured for HA failover of workload route tables between the two Cloud Connectors)<br>

Additionally: Creates 2 Route 53 subnets routing to the service ENI of Cloud Connector; Route 53 outbound resolver endpoint; and Route 53 resolver rules for ZPA DNS redirection.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13.7, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 4.7.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 4.7.0 |
| <a name="provider_local"></a> [local](#provider\_local) | n/a |
| <a name="provider_null"></a> [null](#provider\_null) | n/a |
| <a name="provider_random"></a> [random](#provider\_random) | ~> 3.3.0 |
| <a name="provider_tls"></a> [tls](#provider\_tls) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_bastion"></a> [bastion](#module\_bastion) | ../../modules/terraform-zscc-bastion-aws | n/a |
| <a name="module_cc-iam"></a> [cc-iam](#module\_cc-iam) | ../../modules/terraform-zscc-iam-aws | n/a |
| <a name="module_cc-lambda"></a> [cc-lambda](#module\_cc-lambda) | ../../modules/terraform-zscc-lambda-aws | n/a |
| <a name="module_cc-sg"></a> [cc-sg](#module\_cc-sg) | ../../modules/terraform-zscc-sg-aws | n/a |
| <a name="module_cc-vm"></a> [cc-vm](#module\_cc-vm) | ../../modules/terraform-zscc-ccvm-aws | n/a |
| <a name="module_route53"></a> [route53](#module\_route53) | ../../modules/terraform-zscc-route53-aws | n/a |
| <a name="module_workload"></a> [workload](#module\_workload) | ../../modules/terraform-zscc-workload-aws | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_eip.eip](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_internet_gateway.igw1](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_key_pair.deployer](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair) | resource |
| [aws_nat_gateway.ngw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway) | resource |
| [aws_route_table.cc-rt](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.routetableprivate](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.routetablepublic1](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.rt-r53](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table_association.cc-rt-asssociation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.private-rt-asssociation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.r53-rt-asssociation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.routetablepublic1](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_subnet.cc-subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.privsubnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.pubsubnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.r53-subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.vpc1](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |
| [local_file.testbed](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.testbed_yml](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.user-data-file](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [null_resource.cc-error-checker](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [random_string.suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [tls_private_key.key](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | The AWS region. | `string` | `"us-west-2"` | no |
| <a name="input_az_count"></a> [az\_count](#input\_az\_count) | Default number of subnets to create based on availability zone | `number` | `2` | no |
| <a name="input_bastion_nsg_source_prefix"></a> [bastion\_nsg\_source\_prefix](#input\_bastion\_nsg\_source\_prefix) | CIDR blocks of trusted networks for bastion host ssh access | `list(string)` | <pre>[<br>  "0.0.0.0/0"<br>]</pre> | no |
| <a name="input_cc_callhome_enabled"></a> [cc\_callhome\_enabled](#input\_cc\_callhome\_enabled) | determine whether or not to create the cc-callhome-policy IAM Policy and attach it to the CC IAM Role | `bool` | `true` | no |
| <a name="input_cc_count"></a> [cc\_count](#input\_cc\_count) | Default number of Cloud Connector appliances to create | `number` | `2` | no |
| <a name="input_cc_instance_size"></a> [cc\_instance\_size](#input\_cc\_instance\_size) | Cloud Connector Instance size. Determined by and needs to match  the Cloud Connector Portal provisioning template configuration | `string` | `"small"` | no |
| <a name="input_cc_vm_prov_url"></a> [cc\_vm\_prov\_url](#input\_cc\_vm\_prov\_url) | Zscaler Cloud Connector Provisioning URL | `string` | n/a | yes |
| <a name="input_ccvm_instance_type"></a> [ccvm\_instance\_type](#input\_ccvm\_instance\_type) | Cloud Connector Instance Type | `string` | `"m5.large"` | no |
| <a name="input_domain_names"></a> [domain\_names](#input\_domain\_names) | Domain names fqdn/wildcard to have Route 53 redirect DNS requests to Cloud Connector for ZPA. Refer to terraform.tfvars step 10 | `map(map(string))` | <pre>{<br>  "appseg01": {<br>    "domain_name": "example.com"<br>  }<br>}</pre> | no |
| <a name="input_http_probe_port"></a> [http\_probe\_port](#input\_http\_probe\_port) | port for Cloud Connector cloud init to enable listener port for HTTP probe from LB | `number` | `0` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | The name prefix for all your resources | `string` | `"zsdemo"` | no |
| <a name="input_owner_tag"></a> [owner\_tag](#input\_owner\_tag) | populate custom owner tag attribute | `string` | `"zscc-admin"` | no |
| <a name="input_reuse_iam"></a> [reuse\_iam](#input\_reuse\_iam) | Specifies whether the SG module should create 1:1 IAM per instance or 1 IAM for all instances | `bool` | `false` | no |
| <a name="input_reuse_security_group"></a> [reuse\_security\_group](#input\_reuse\_security\_group) | Specifies whether the SG module should create 1:1 security groups per instance or 1 security group for all instances | `bool` | `false` | no |
| <a name="input_secret_name"></a> [secret\_name](#input\_secret\_name) | AWS Secrets Manager Secret Name for Cloud Connector provisioning | `string` | n/a | yes |
| <a name="input_target_address"></a> [target\_address](#input\_target\_address) | Route 53 DNS queries will be forwarded to these Zscaler Global VIP addresses | `list(string)` | <pre>[<br>  "185.46.212.88",<br>  "185.46.212.89"<br>]</pre> | no |
| <a name="input_tls_key_algorithm"></a> [tls\_key\_algorithm](#input\_tls\_key\_algorithm) | algorithm for tls\_private\_key resource | `string` | `"RSA"` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | VPC CIDR | `number` | `"10.1.0.0/16"` | no |
| <a name="input_workload_count"></a> [workload\_count](#input\_workload\_count) | Default number of workload VMs to create | `number` | `2` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_testbedconfig"></a> [testbedconfig](#output\_testbedconfig) | n/a |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->