output "gwlbe" {
  description = "GWLB Endpoint ID"
  value       = aws_vpc_endpoint.gwlb_vpce.*.id
}

output "vpce_service_name" {
  description = "VPC Endpoint Service Name"
  value       = aws_vpc_endpoint_service.gwlb_vpce_service.service_name
}
