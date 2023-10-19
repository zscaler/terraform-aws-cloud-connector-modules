output "gwlbe" {
  description = "GWLB Endpoint ID"
  value       = aws_vpc_endpoint.gwlb_vpce[*].id
}

output "vpce_service_name" {
  description = "VPC Endpoint Service Name"
  value       = aws_vpc_endpoint_service.gwlb_vpce_service.service_name
}

output "vpce_service_id" {
  description = "VPC Endpoint Service ID"
  value       = aws_vpc_endpoint_service.gwlb_vpce_service.id
}

output "vpce_service_arn" {
  description = "VPC Endpoint Service ARN"
  value       = aws_vpc_endpoint_service.gwlb_vpce_service.arn
}
