# terraform-zscc-tgw-aws

This module encapsulates all AWS Transit Gateway Hub-and-Spoke resources required for Zscaler Cloud Connector centralized inspection deployments.

## Overview

The module provisions:
- An AWS Transit Gateway (with custom route tables, default association/propagation disabled)
- TGW VPC Attachments for one Hub VPC and two Spoke VPCs
  - The **Hub attachment has `appliance_mode_support = "enable"`** — this is required for GWLB-based inspection. Without it, TGW may route return traffic through a different AZ ENI than the original flow, breaking GWLB's 5-tuple flow stickiness and causing traffic to bypass Cloud Connector inspection.
- Two TGW route tables:
  - **spoke_rt** — associated to both spoke attachments; static `0.0.0.0/0 → hub` default route forces all spoke egress through the hub
  - **hub_rt** — associated to the hub attachment; propagates spoke CIDRs for return traffic routing
- VPC routes in the Hub:
  - TGW attach subnet route tables: `0.0.0.0/0 → GWLB endpoint` (one per AZ) + spoke CIDRs → TGW
  - GWLB endpoint subnet route tables: spoke CIDRs → TGW (return path after CC inspection)

## Traffic Flow

```
Spoke Workload → TGW (spoke_rt: 0.0.0.0/0 → hub)
  → Hub TGW-Attach Subnet (route: 0.0.0.0/0 → GWLB Endpoint)
  → GWLB Endpoint → GWLB → Cloud Connector
  → NAT Gateway → Internet

Return path:
Internet → NAT GW → CC → GWLB → GWLB Endpoint
  → Hub GWLB-Endpoint Subnet (route: spoke_cidr → TGW)
  → TGW (hub_rt propagates spoke CIDRs)
  → Spoke Workload
```

## Usage

```hcl
module "tgw" {
  source     = "../../modules/terraform-zscc-tgw-aws"
  name_prefix = var.name_prefix
  resource_tag = random_string.suffix.result
  global_tags  = local.global_tags
  tgw_name     = var.tgw_name
  az_count     = var.az_count

  # Hub VPC — sourced from terraform-zscc-network-aws outputs
  hub_vpc_id                        = module.network.vpc_id
  hub_tgw_attach_subnet_ids         = module.network.tgw_attach_subnet_ids
  hub_tgw_attach_route_table_ids    = module.network.tgw_attach_route_table_ids
  hub_gwlb_endpoint_route_table_ids = module.network.gwlb_endpoint_route_table_ids
  gwlb_endpoint_ids                 = module.gwlb_endpoint.gwlbe

  # Spoke 1
  spoke_1_vpc_id              = aws_vpc.spoke_1[0].id
  spoke_1_vpc_cidr            = var.spoke_1_vpc_cidr
  spoke_1_workload_subnet_ids = aws_subnet.spoke_1_workload[*].id

  # Spoke 2
  spoke_2_vpc_id              = aws_vpc.spoke_2[0].id
  spoke_2_vpc_cidr            = var.spoke_2_vpc_cidr
  spoke_2_workload_subnet_ids = aws_subnet.spoke_2_workload[*].id
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.13.7, < 2.0.0 |
| aws | ~> 5.32 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `name_prefix` | Prefix for all resource names | `string` | `null` | no |
| `resource_tag` | Tag suffix appended to all resource names | `string` | `null` | no |
| `global_tags` | Map of custom tags applied to all resources | `map(string)` | `{}` | no |
| `tgw_name` | Name tag for the Transit Gateway | `string` | `"zscc-tgw"` | no |
| `az_count` | Number of Availability Zones (controls per-AZ route count) | `number` | `2` | no |
| `hub_vpc_id` | VPC ID of the Hub VPC | `string` | — | yes |
| `hub_tgw_attach_subnet_ids` | TGW attach subnet IDs in Hub VPC (one per AZ) | `list(string)` | — | yes |
| `hub_tgw_attach_route_table_ids` | Route table IDs for Hub TGW attach subnets | `list(string)` | — | yes |
| `hub_gwlb_endpoint_route_table_ids` | Route table IDs for Hub GWLB endpoint subnets | `list(string)` | — | yes |
| `gwlb_endpoint_ids` | GWLB Endpoint IDs (one per AZ) for spoke→CC steering | `list(string)` | — | yes |
| `spoke_1_vpc_id` | VPC ID of Spoke 1 | `string` | — | yes |
| `spoke_1_vpc_cidr` | CIDR block of Spoke 1 VPC | `string` | — | yes |
| `spoke_1_workload_subnet_ids` | Workload subnet IDs in Spoke 1 for TGW attachment | `list(string)` | — | yes |
| `spoke_2_vpc_id` | VPC ID of Spoke 2 | `string` | — | yes |
| `spoke_2_vpc_cidr` | CIDR block of Spoke 2 VPC | `string` | — | yes |
| `spoke_2_workload_subnet_ids` | Workload subnet IDs in Spoke 2 for TGW attachment | `list(string)` | — | yes |

## Outputs

| Name | Description |
|------|-------------|
| `tgw_id` | Transit Gateway ID |
| `tgw_arn` | Transit Gateway ARN |
| `hub_attachment_id` | TGW VPC Attachment ID for the Hub VPC |
| `spoke_1_attachment_id` | TGW VPC Attachment ID for Spoke 1 VPC |
| `spoke_2_attachment_id` | TGW VPC Attachment ID for Spoke 2 VPC |
| `spoke_route_table_id` | TGW Route Table ID for spoke attachments |
| `hub_route_table_id` | TGW Route Table ID for the hub attachment |
