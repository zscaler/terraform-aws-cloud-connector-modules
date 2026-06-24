################################################################################
# Availability Zones — used for spoke subnet AZ assignment in TGW mode
################################################################################
data "aws_availability_zones" "available" {
  state = "available"
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}


################################################################################
# Transit Gateway Hub-and-Spoke — centralized inspection via GWLB
#
# All resources in this block are created only when tgw_enabled = true.
#
# The terraform-zscc-tgw-aws module encapsulates:
#   - Transit Gateway + two route tables (spoke_rt, hub_rt)
#   - TGW VPC Attachments (hub + all spokes defined in var.spokes)
#   - TGW route table associations and propagations
#   - VPC routes in Hub: TGW-attach subnets → GWLB endpoints (0.0.0.0/0 only)
#   - VPC routes in Hub: GWLB-endpoint subnets → TGW (spoke return path)
#
# Spoke VPC primitives (VPC, subnets, route tables, IGW, bastion, workloads)
# are defined in spokes.tf using for_each over var.spokes.
################################################################################
module "tgw" {
  count  = var.tgw_enabled ? 1 : 0
  source = "../../modules/terraform-zscc-tgw-aws"

  name_prefix  = var.name_prefix
  resource_tag = random_string.suffix.result
  global_tags  = local.global_tags
  tgw_name     = var.tgw_name
  az_count     = var.az_count

  # Hub VPC — sourced from the network module
  hub_vpc_id                        = module.network.vpc_id
  hub_tgw_attach_subnet_ids         = module.network.tgw_attach_subnet_ids
  hub_tgw_attach_route_table_ids    = module.network.tgw_attach_route_table_ids
  hub_gwlb_endpoint_route_table_ids = module.network.gwlb_endpoint_route_table_ids
  hub_cc_route_table_ids            = module.network.cc_subnet_route_table_ids
  gwlb_endpoint_ids                 = module.gwlb_endpoint.gwlbe

  # Spoke 1 — sourced from spokes.tf for_each resources
  spoke_1_vpc_id              = aws_vpc.spoke["spoke-1"].id
  spoke_1_vpc_cidr            = var.spokes["spoke-1"].cidr
  spoke_1_workload_subnet_ids = [for k, s in aws_subnet.spoke_workload : s.id if can(regex("^spoke-1-", k))]

  # Spoke 2 — sourced from spokes.tf for_each resources
  spoke_2_vpc_id              = aws_vpc.spoke["spoke-2"].id
  spoke_2_vpc_cidr            = var.spokes["spoke-2"].cidr
  spoke_2_workload_subnet_ids = [for k, s in aws_subnet.spoke_workload : s.id if can(regex("^spoke-2-", k))]
}
