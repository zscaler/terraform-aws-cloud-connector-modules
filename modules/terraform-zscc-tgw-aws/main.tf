################################################################################
# terraform-zscc-tgw-aws
#
# Encapsulates all Transit Gateway Hub-and-Spoke resources for Zscaler Cloud
# Connector centralized inspection deployments.
#
# TGW Route Table design:
#   spoke_rt : associated to Spoke 1 + Spoke 2 attachments
#              static route 0.0.0.0/0 → Hub attachment (all spoke egress → Hub)
#   hub_rt   : associated to Hub attachment
#              propagates spoke CIDRs from both spoke attachments (return path)
#
# VPC Route additions (Hub):
#   tgw_attach RT    : 0.0.0.0/0 → GWLB endpoint (one per AZ, steers ALL ingress
#                      traffic to CC — egress and East-West alike).
#                      NOTE: per-spoke routes are intentionally omitted; adding
#                      spoke_X_cidr routes here would cause East-West traffic to
#                      match the more-specific route and bypass CC inspection.
#   gwlb_endpoint RT : spoke_1_vpc_cidr → TGW  (post-inspection return to Spoke 1)
#                      spoke_2_vpc_cidr → TGW  (post-inspection return to Spoke 2)
#                      (0.0.0.0/0 → NAT GW is pre-wired by terraform-zscc-network-aws)
################################################################################


################################################################################
# Transit Gateway
################################################################################
resource "aws_ec2_transit_gateway" "tgw" {
  description                     = "${var.name_prefix}-hub-spoke-tgw-${var.resource_tag}"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"

  # Pin optional features explicitly for reproducibility across AWS regions.
  # Leaving these unset causes Terraform drift when AWS changes regional defaults.
  dns_support       = "enable"
  vpn_ecmp_support  = "enable"
  multicast_support = "disable"

  tags = merge(var.global_tags, {
    Name = "${var.tgw_name}-${var.resource_tag}"
  })
}


################################################################################
# TGW VPC Attachments — Hub + Spoke 1 + Spoke 2
################################################################################
resource "aws_ec2_transit_gateway_vpc_attachment" "hub" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  vpc_id             = var.hub_vpc_id
  subnet_ids         = var.hub_tgw_attach_subnet_ids

  # appliance_mode_support is required for GWLB-based inspection.
  # Without it, TGW may route return traffic through a different AZ ENI than
  # the one the original flow arrived on, breaking GWLB's 5-tuple flow stickiness
  # and causing traffic to bypass the Cloud Connector.
  appliance_mode_support = "enable"

  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = merge(var.global_tags, {
    Name = "${var.name_prefix}-tgw-attach-hub-${var.resource_tag}"
  })
}

resource "aws_ec2_transit_gateway_vpc_attachment" "spoke_1" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  vpc_id             = var.spoke_1_vpc_id
  subnet_ids         = var.spoke_1_workload_subnet_ids

  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = merge(var.global_tags, {
    Name = "${var.name_prefix}-tgw-attach-spoke-1-${var.resource_tag}"
  })
}

resource "aws_ec2_transit_gateway_vpc_attachment" "spoke_2" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  vpc_id             = var.spoke_2_vpc_id
  subnet_ids         = var.spoke_2_workload_subnet_ids

  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = merge(var.global_tags, {
    Name = "${var.name_prefix}-tgw-attach-spoke-2-${var.resource_tag}"
  })
}


################################################################################
# TGW Route Tables
################################################################################
resource "aws_ec2_transit_gateway_route_table" "spoke_rt" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id

  tags = merge(var.global_tags, {
    Name = "${var.name_prefix}-tgw-spoke-rt-${var.resource_tag}"
  })
}

resource "aws_ec2_transit_gateway_route_table" "hub_rt" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id

  tags = merge(var.global_tags, {
    Name = "${var.name_prefix}-tgw-hub-rt-${var.resource_tag}"
  })
}


################################################################################
# TGW Route Table Associations
################################################################################
resource "aws_ec2_transit_gateway_route_table_association" "spoke_1_assoc" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.spoke_1.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke_rt.id
}

resource "aws_ec2_transit_gateway_route_table_association" "spoke_2_assoc" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.spoke_2.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke_rt.id
}

resource "aws_ec2_transit_gateway_route_table_association" "hub_assoc" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.hub.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.hub_rt.id
}


################################################################################
# TGW Routes
# Spoke RT: static default route → Hub attachment (all spoke traffic → Hub VPC)
################################################################################
resource "aws_ec2_transit_gateway_route" "spoke_default_to_hub" {
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.hub.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke_rt.id
}


################################################################################
# TGW Route Table Propagations
# Hub RT: propagate each spoke's CIDR so Hub knows how to return traffic to spokes
################################################################################
resource "aws_ec2_transit_gateway_route_table_propagation" "spoke_1_to_hub_rt" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.spoke_1.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.hub_rt.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "spoke_2_to_hub_rt" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.spoke_2.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.hub_rt.id
}


################################################################################
# VPC Routes — Hub TGW attach subnet RTs
#
# Only a single default route 0.0.0.0/0 → GWLB endpoint is needed here.
# This steers ALL traffic arriving from TGW (egress and East-West) to CC for
# inspection, regardless of destination.
#
# Per-spoke routes (spoke_X_cidr → TGW) are intentionally NOT added here:
# adding them would make East-West traffic (Spoke-1→Spoke-2) match the more-
# specific spoke-2 route and bypass the GWLBe → CC inspection path entirely.
# The TGW return path for inspected traffic is handled in the GWLBe subnet RT.
################################################################################
resource "aws_route" "hub_tgw_attach_to_gwlbe" {
  count                  = var.az_count
  route_table_id         = var.hub_tgw_attach_route_table_ids[count.index]
  destination_cidr_block = "0.0.0.0/0"
  vpc_endpoint_id        = var.gwlb_endpoint_ids[count.index]

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.hub]
}


################################################################################
# VPC Routes — Hub CC subnet RTs
#
# CC's service interface lives in the CC subnet. When CC forwards inspected
# East-West traffic (e.g. Spoke-1→Spoke-2), the response from the destination
# spoke returns to CC, which then sends it back via its service interface.
# Without these routes, the CC subnet RT's default 0.0.0.0/0 → NAT GW would
# send that return traffic to the internet instead of back to the source spoke.
# Adding spoke CIDR → TGW routes here ensures symmetric return routing.
################################################################################
resource "aws_route" "hub_cc_to_spoke_1" {
  count                  = length(var.hub_cc_route_table_ids)
  route_table_id         = var.hub_cc_route_table_ids[count.index]
  destination_cidr_block = var.spoke_1_vpc_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.tgw.id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.hub]
}

resource "aws_route" "hub_cc_to_spoke_2" {
  count                  = length(var.hub_cc_route_table_ids)
  route_table_id         = var.hub_cc_route_table_ids[count.index]
  destination_cidr_block = var.spoke_2_vpc_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.tgw.id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.hub]
}


################################################################################
# VPC Routes — Hub GWLB endpoint subnet RTs
#
# After CC returns inspected traffic through the GWLB Endpoint, response packets
# destined for spoke private IPs must be routed back via TGW.
# The 0.0.0.0/0 → NAT GW route is pre-wired in terraform-zscc-network-aws.
################################################################################
resource "aws_route" "hub_gwlb_endpoint_to_spoke_1" {
  count                  = var.az_count
  route_table_id         = var.hub_gwlb_endpoint_route_table_ids[count.index]
  destination_cidr_block = var.spoke_1_vpc_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.tgw.id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.hub]
}

resource "aws_route" "hub_gwlb_endpoint_to_spoke_2" {
  count                  = var.az_count
  route_table_id         = var.hub_gwlb_endpoint_route_table_ids[count.index]
  destination_cidr_block = var.spoke_2_vpc_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.tgw.id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.hub]
}
