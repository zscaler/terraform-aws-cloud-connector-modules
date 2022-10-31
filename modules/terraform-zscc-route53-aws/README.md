# Zscaler Cloud Connector / AWS Route 53 DNS Module

This module creates Route 53 Resolver Rules and Endpoints for utilization with DNS redirection to facilitate Cloud Connector ZPA service.

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
| [aws_route53_resolver_endpoint.zpa_r53_ep](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_resolver_endpoint) | resource |
| [aws_route53_resolver_rule.fwd](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_resolver_rule) | resource |
| [aws_route53_resolver_rule.system](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_resolver_rule) | resource |
| [aws_route53_resolver_rule_association.r53_rule_association_fwd](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_resolver_rule_association) | resource |
| [aws_route53_resolver_rule_association.r53_rule_association_system](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_resolver_rule_association) | resource |
| [aws_security_group.selected](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/security_group) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_domain_names"></a> [domain\_names](#input\_domain\_names) | Domain names fqdn/wildcard to have Route 53 redirect DNS requests to Cloud Connector for ZPA. Refer to terraform.tfvars step 10 | `map(map(string))` | <pre>{<br>  "appseg01": {<br>    "domain_name": "example.com"<br>  }<br>}</pre> | no |
| <a name="input_global_tags"></a> [global\_tags](#input\_global\_tags) | Populate any custom user defined tags from a map | `map(string)` | `{}` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | A prefix to associate to all Route 53 module resources | `string` | `null` | no |
| <a name="input_r53_subnet_ids"></a> [r53\_subnet\_ids](#input\_r53\_subnet\_ids) | List of Subnet IDs for the Route53 Endpoint | `list(string)` | n/a | yes |
| <a name="input_resource_tag"></a> [resource\_tag](#input\_resource\_tag) | A tag to associate to all Route 53 module resources | `string` | `null` | no |
| <a name="input_target_address"></a> [target\_address](#input\_target\_address) | Route 53 DNS queries will be forwarded to these Zscaler Global VIP addresses | `list(string)` | <pre>[<br>  "185.46.212.88",<br>  "185.46.212.89"<br>]</pre> | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID for the Route 53 Endpoints | `string` | n/a | yes |
| <a name="input_zscaler_domains"></a> [zscaler\_domains](#input\_zscaler\_domains) | Domains that Route 53 should not forward to Cloud Connector | `map(map(string))` | <pre>{<br>  "ZS-FreeBSD": {<br>    "domain_name": "freebsd.org"<br>  },<br>  "ZS-NTP": {<br>    "domain_name": "ntp.org"<br>  },<br>  "ZS-ZPABeta": {<br>    "domain_name": "zpabeta.net"<br>  },<br>  "ZS-ZPAGov": {<br>    "domain_name": "zpagov.net"<br>  },<br>  "ZS-Zpath": {<br>    "domain_name": "zpath.net"<br>  },<br>  "ZS-ZsCloud": {<br>    "domain_name": "zscloud.net"<br>  },<br>  "ZS-ZsNet": {<br>    "domain_name": "zscaler.net"<br>  },<br>  "ZS-Zscaler": {<br>    "domain_name": "zscaler.com"<br>  },<br>  "ZS-ZscalerBeta": {<br>    "domain_name": "zscalerbeta.net"<br>  },<br>  "ZS-ZscalerGov": {<br>    "domain_name": "zscalergov.net"<br>  },<br>  "ZS-ZscalerOne": {<br>    "domain_name": "zscalerone.net"<br>  },<br>  "ZS-ZscalerThree": {<br>    "domain_name": "zscalerthree.net"<br>  },<br>  "ZS-ZscalerTwo": {<br>    "domain_name": "zscalertwo.net"<br>  }<br>}</pre> | no |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
