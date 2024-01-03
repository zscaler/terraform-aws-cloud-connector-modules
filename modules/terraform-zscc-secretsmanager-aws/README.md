# Zscaler Cloud Connector / AWS Secrets Manager Module

This module creates a new Secrets Manger Secret in the region where Cloud Connector is being deployed. It will also populate the secret values with Zscaler customer provided inputs of api_key, username, and password. Optionally, if the customer already has a Secret they would rather use, this can be provided with variable byo_secret value of true and setting the variable secret_name to match the friendly name that already exist from the Secret in the same customer AWS account

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13.7, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.59, <= 5.17 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.59, <= 5.17 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_secretsmanager_secret.cloud_connector_secret](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_version.cloud_connector_secret_values](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [aws_secretsmanager_secret.cloud_connector_secret_selected](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_byo_secret"></a> [byo\_secret](#input\_byo\_secret) | True/False to conditionally create a new secret. Default is false meaning create a new resource | `bool` | `false` | no |
| <a name="input_global_tags"></a> [global\_tags](#input\_global\_tags) | Populate any custom user defined tags from a map | `map(string)` | `{}` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | A prefix to associate to all the Cloud Connector Secrets Manager module resources | `string` | `null` | no |
| <a name="input_resource_tag"></a> [resource\_tag](#input\_resource\_tag) | A tag to associate to all the Cloud Connector Secrets Manager module resources | `string` | `null` | no |
| <a name="input_secret_name"></a> [secret\_name](#input\_secret\_name) | AWS Secrets Manager Secret Name for Cloud Connector provisioning. This could be a new name or existing depending on byo\_secret value | `string` | `""` | no |
| <a name="input_zscaler_api_key"></a> [zscaler\_api\_key](#input\_zscaler\_api\_key) | Zscaler Cloud Connector API Key. Only required/used if var.byo\_secret is false | `string` | n/a | yes |
| <a name="input_zscaler_password"></a> [zscaler\_password](#input\_zscaler\_password) | Zscaler Cloud Connector deploy password. Only required/used if var.byo\_secret is false | `string` | n/a | yes |
| <a name="input_zscaler_username"></a> [zscaler\_username](#input\_zscaler\_username) | Zscaler Cloud Connector deploy username. Only required/used if var.byo\_secret is false | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_secret_id"></a> [secret\_id](#output\_secret\_id) | Secrets Manager Secret ARN |
| <a name="output_secret_name"></a> [secret\_name](#output\_secret\_name) | Secrets Manager Secret friendly name |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
