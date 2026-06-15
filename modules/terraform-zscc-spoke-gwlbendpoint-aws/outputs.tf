output "gwlbe" {
  description = "GWLB Endpoint ID"
  value       = aws_vpc_endpoint.gwlb_vpce[*].id
}