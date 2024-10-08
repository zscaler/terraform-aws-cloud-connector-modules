output "gwlbe" {
  description = "GWLB Endpoint ID"
  value       = aws_vpc_endpoint.gwlb_vpce[*].id
}

output "vpce_service_name" {
  description = "VPC Endpoint Service Name"
  value       = try(data.aws_vpc_endpoint_service.gwlb_vpce_service_selected[0].service_name, aws_vpc_endpoint_service.gwlb_vpce_service[0].service_name)
}

output "vpce_service_id" {
  description = "VPC Endpoint Service ID"
  value       = try(data.aws_vpc_endpoint_service.gwlb_vpce_service_selected[0].id, aws_vpc_endpoint_service.gwlb_vpce_service[0].id)
}

output "vpce_service_arn" {
  description = "VPC Endpoint Service ARN"
  value       = try(data.aws_vpc_endpoint_service.gwlb_vpce_service_selected[0].arn, aws_vpc_endpoint_service.gwlb_vpce_service[0].arn)
}
