output "vpc_id" {
  description = "VPC ID"
  value       = try(data.aws_vpc.vpc_selected[0].id, aws_vpc.vpc[0].id)
}

output "cc_subnet_ids" {
  description = "Cloud Connector Subnet ID"
  value       = data.aws_subnet.cc_subnet_selected[*].id
}

output "workload_subnet_ids" {
  description = "Workloads Subnet ID"
  value       = aws_subnet.workload_subnet[*].id
}

output "public_subnet_ids" {
  description = "Public Subnet ID"
  value       = aws_subnet.public_subnet[*].id
}

output "route53_subnet_ids" {
  description = "Route 53 Subnet ID"
  value       = length(var.byo_r53_subnet_ids) == 0 ? aws_subnet.route53_subnet[*].id : data.aws_subnet.route53_subnet_selected[*].id
}

output "nat_gateway_ips" {
  description = "NAT Gateway Public IP"
  value       = data.aws_nat_gateway.ngw_selected[*].public_ip
}

output "workload_route_table_ids" {
  description = "Workloads Route Table ID"
  value       = aws_route_table_association.workload_rt_association[*].route_table_id
}

output "nat_gateway_ids" {
  description = "NAT Gateway IDs"
  value       = data.aws_nat_gateway.ngw_selected[*].id
}

output "tgw_attach_subnet_ids" {
  description = "TGW Attach Subnet IDs (populated only when tgw_enabled = true)"
  value       = aws_subnet.tgw_attach_subnet[*].id
}

output "tgw_attach_route_table_ids" {
  description = "TGW Attach Route Table IDs (populated only when tgw_enabled = true)"
  value       = aws_route_table.tgw_attach_rt[*].id
}

output "gwlb_endpoint_subnet_ids" {
  description = "GWLB Endpoint Subnet IDs (populated only when tgw_enabled = true)"
  value       = aws_subnet.gwlb_endpoint_subnet[*].id
}

output "gwlb_endpoint_route_table_ids" {
  description = "GWLB Endpoint Route Table IDs (populated only when tgw_enabled = true)"
  value       = aws_route_table.gwlb_endpoint_rt[*].id
}

output "cc_subnet_route_table_ids" {
  description = "CC Subnet Route Table IDs. Used in TGW mode to add spoke CIDR → TGW routes so East-West return traffic from CC reaches spoke VPCs via TGW instead of NAT GW."
  value       = aws_route_table.cc_rt[*].id
}
