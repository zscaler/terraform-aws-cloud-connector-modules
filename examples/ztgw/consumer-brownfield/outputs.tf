# ==============================================================================
# examples/aws/consumer-brownfield — outputs
# ==============================================================================

output "vpc_endpoint_id" {
  description = "The ID of the primary VPC Endpoint interface."
  value       = module.gwlb_consumer.endpoint_id
}

output "vpc_endpoint_ids" {
  description = "Map of subnet_id to VPC Endpoint interface IDs."
  value       = module.gwlb_consumer.endpoint_ids
}

output "vpc_endpoint_arn" {
  description = "The ARN of the primary VPC Endpoint."
  value       = module.gwlb_consumer.endpoint_arn
}

output "route_ids" {
  description = "Map of route table IDs to created ZTGW default route IDs."
  value       = module.gwlb_consumer.route_ids
}
