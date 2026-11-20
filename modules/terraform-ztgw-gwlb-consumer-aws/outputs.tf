# -----------------------------------------------------------------------------
# modules/consumer-aws/gwlb-consumer — outputs
# -----------------------------------------------------------------------------

output "endpoint_id" {
  description = "The ID of the primary AWS VPC Endpoint (GatewayLoadBalancer)."
  value       = values(aws_vpc_endpoint.this)[0].id
}

output "endpoint_ids" {
  description = "Map of subnet ID to created GatewayLoadBalancer VPC Endpoint ID."
  value       = { for k, v in aws_vpc_endpoint.this : k => v.id }
}

output "endpoint_arn" {
  description = "The ARN of the primary AWS VPC Endpoint."
  value       = values(aws_vpc_endpoint.this)[0].arn
}

output "network_interface_ids" {
  description = "Network interface IDs created on the endpoint subnets."
  value       = flatten([for ep in aws_vpc_endpoint.this : ep.network_interface_ids])
}

output "route_ids" {
  description = "Map of route table ID to created route ID."
  value       = { for k, v in aws_route.workload_to_ztgw : k => v.id }
}
