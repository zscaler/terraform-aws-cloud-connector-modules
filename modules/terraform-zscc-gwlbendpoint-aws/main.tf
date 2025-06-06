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
# Create the Endpoint Service for Gateway Load Balancer.
# Default auto accept and allow all principals on the current AWS Account 
# if no explicit principals are configured in var.allowed_principals
################################################################################
resource "aws_vpc_endpoint_service" "gwlb_vpce_service" {
  count                      = var.byo_endpoint_service_name != null ? 0 : 1
  allowed_principals         = coalescelist(var.allowed_principals, ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.id}:root"])
  acceptance_required        = var.acceptance_required
  gateway_load_balancer_arns = [var.gwlb_arn]

  tags = merge(var.global_tags,
    { Name = "${var.name_prefix}-cc-gwlb-vpce-service-${var.resource_tag}" }
  )
}

# Or reference an existing Endpoint Service
data "aws_vpc_endpoint_service" "gwlb_vpce_service_selected" {
  count        = var.byo_endpoint_service_name != null ? 1 : 0
  service_name = var.byo_endpoint_service_name
}



################################################################################
# Create the GWLB Endpoint ENIs per list of subnet IDs specified
################################################################################
resource "aws_vpc_endpoint" "gwlb_vpce" {
  count             = length(var.subnet_ids)
  service_name      = try(data.aws_vpc_endpoint_service.gwlb_vpce_service_selected[0].service_name, aws_vpc_endpoint_service.gwlb_vpce_service[0].service_name)
  subnet_ids        = [element(var.subnet_ids, count.index)]
  vpc_endpoint_type = try(data.aws_vpc_endpoint_service.gwlb_vpce_service_selected[0].service_type, aws_vpc_endpoint_service.gwlb_vpce_service[0].service_type)
  vpc_id            = var.vpc_id

  tags = merge(var.global_tags,
    { Name = "${var.name_prefix}-client-vpce-az${count.index + 1}-${var.resource_tag}" }
  )
}
