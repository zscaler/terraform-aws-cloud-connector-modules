################################################################################
#  Pull the Account ID number of the account that owns or contains the calling 
#  entity
################################################################################
data "aws_caller_identity" "current" {}


################################################################################
# Pull AWS partition
################################################################################
data "aws_partition" "current" {}

################################################################################
# Create the GWLB Endpoint ENIs per list of subnet IDs specified
################################################################################
resource "aws_vpc_endpoint" "gwlb_vpce" {
  count             = length(var.subnet_ids)
  service_name      = var.endpoint_service_name
  subnet_ids        = [element(var.subnet_ids, count.index)]
  vpc_endpoint_type = "GatewayLoadBalancer"
  vpc_id            = var.vpc_id

  tags = merge(var.global_tags,
    { Name = "${var.name_prefix}-client-vpce-az${count.index + 1}-${var.resource_tag}" }
  )
}
