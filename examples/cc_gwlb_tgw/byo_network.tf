################################################################################
# BYO Network — data sources for existing Hub VPC infrastructure
#
# This brownfield example assumes the customer has an existing:
#   - Hub VPC with CC, TGW-attach, and GWLB-endpoint subnets
#   - Transit Gateway with Hub + Spoke VPC attachments
#   - NAT Gateways and route tables in the Hub VPC
#   - Spoke VPCs with workloads already routing to TGW
#
# Terraform will:
#   - Deploy CC VMs, GWLB, and GWLB Endpoints into the existing infrastructure
#   - Inject routing entries into existing TGW-attach and GWLB-endpoint route tables
################################################################################

data "aws_availability_zones" "available" {
  state = "available"
}

################################################################################
# Hub VPC lookup
################################################################################
data "aws_vpc" "hub" {
  id = var.byo_vpc_id
}

################################################################################
# CC Subnets — existing subnets where Cloud Connector VMs will be deployed
# One subnet per AZ, provided via byo_cc_subnet_ids (ordered by AZ)
################################################################################
data "aws_subnet" "cc" {
  count = var.az_count
  id    = var.byo_cc_subnet_ids[count.index]
}

################################################################################
# TGW Attach Subnets — existing subnets where TGW ENIs are attached
# Route table for these subnets will have 0.0.0.0/0 → GWLB Endpoint added
################################################################################
data "aws_subnet" "tgw_attach" {
  count = var.az_count
  id    = var.byo_tgw_attach_subnet_ids[count.index]
}

################################################################################
# GWLB Endpoint Subnets — existing subnets where GWLB Endpoint ENIs will land
# Route table for these subnets will have spoke CIDRs → TGW added (return path)
################################################################################
data "aws_subnet" "gwlb_endpoint" {
  count = var.az_count
  id    = var.byo_gwlb_endpoint_subnet_ids[count.index]
}

################################################################################
# Transit Gateway lookup
################################################################################
data "aws_ec2_transit_gateway" "tgw" {
  id = var.byo_tgw_id
}
