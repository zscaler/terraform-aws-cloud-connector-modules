# Create the Endpint Service for Gateway Load Balancer
resource "aws_vpc_endpoint_service" "gwlb-vpce-service" {
  acceptance_required        = false
  gateway_load_balancer_arns = [var.gwlb_arn]

  tags = merge(var.global_tags,
        { Name = "${var.name_prefix}-cc-gwlb-vpce-service-${var.resource_tag}" }
  )
}


resource "aws_vpc_endpoint" "gwlb-vpce" {
  count               = length(var.cc_subnet_ids)
  service_name        = aws_vpc_endpoint_service.gwlb-vpce-service.service_name
  subnet_ids          = [element(var.cc_subnet_ids, count.index)]
  vpc_endpoint_type   = aws_vpc_endpoint_service.gwlb-vpce-service.service_type
  vpc_id              = var.vpc

  tags = merge(var.global_tags,
        { Name = "${var.name_prefix}-client-vpce-az${count.index + 1}-${var.resource_tag}" }
  )
}
