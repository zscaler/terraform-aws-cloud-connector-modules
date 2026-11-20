# ==============================================================================
# examples/aws/gateway-only — outputs
# ==============================================================================

output "gateway_id" {
  description = "The Zscaler Cloud-assigned unique ID for this ZTGW."
  value       = module.ztgw_gateway.gateway_id
}

output "gateway_name" {
  description = "The user-assigned name of the ZTGW."
  value       = module.ztgw_gateway.gateway_name
}

output "gateway_health_status" {
  description = "Current reported health status of the ZTGW (HEALTHY)."
  value       = module.ztgw_gateway.health_status
}

output "endpoint_service_name" {
  description = "The AWS Gateway Load Balancer Endpoint Service name (hand off to application / cloud teams)."
  value       = module.ztgw_gateway.endpoint_service_name
}
