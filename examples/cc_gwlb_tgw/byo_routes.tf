################################################################################
# BYO Routes — inject required routing entries into existing route tables
#
# Two sets of routes are added:
#
# 1. TGW Attach subnet route tables (one per AZ):
#    0.0.0.0/0 → GWLB Endpoint (in the same AZ)
#    This steers all traffic arriving from TGW into CC for inspection.
#
# 2. GWLB Endpoint subnet route tables (one entry per spoke CIDR per AZ):
#    <spoke_cidr> → Transit Gateway
#    This provides the return path for east-west traffic after inspection,
#    routing inspected packets back to the originating or destination spoke.
################################################################################

################################################################################
# 1. TGW Attach RT → GWLB Endpoint (one route per AZ)
#    Default route steers all spoke-originated traffic to the GWLB Endpoint
#    in the same AZ for symmetric inspection.
################################################################################
resource "aws_route" "tgw_attach_to_gwlbe" {
  count                  = var.az_count
  route_table_id         = var.byo_tgw_attach_rt_ids[count.index]
  destination_cidr_block = "0.0.0.0/0"
  vpc_endpoint_id        = module.gwlb_endpoint.gwlbe[count.index]

  depends_on = [module.gwlb_endpoint]
}


################################################################################
# 2. GWLB Endpoint RT → TGW for spoke return paths
#    Creates one route per (AZ route table, spoke CIDR) combination.
#    After CC inspection, east-west return traffic is routed back via TGW
#    to the correct spoke VPC.
################################################################################
locals {
  gwlbe_rt_spoke_routes = flatten([
    for az_idx, rt_id in var.byo_gwlb_endpoint_rt_ids : [
      for cidr in var.spoke_vpc_cidrs : {
        key   = "${az_idx}-${cidr}"
        rt_id = rt_id
        cidr  = cidr
      }
    ]
  ])
}

resource "aws_route" "gwlbe_to_tgw" {
  for_each               = { for r in local.gwlbe_rt_spoke_routes : r.key => r }
  route_table_id         = each.value.rt_id
  destination_cidr_block = each.value.cidr
  transit_gateway_id     = var.byo_tgw_id
}
