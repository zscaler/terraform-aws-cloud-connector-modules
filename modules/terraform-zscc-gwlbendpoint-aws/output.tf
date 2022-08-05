output "gwlbe" {
  value = aws_vpc_endpoint.gwlb-vpce.*.id
}

output "vpce_service_name" {
  value = aws_vpc_endpoint_service.gwlb-vpce-service.service_name
}