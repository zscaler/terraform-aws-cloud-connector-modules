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
  value       = aws_subnet.route53_subnet[*].id
}

output "nat_gateway_ips" {
  description = "NAT Gateway Public IP"
  value       = data.aws_nat_gateway.ngw_selected[*].public_ip
}

output "workload_route_table_ids" {
  description = "Workloads Route Table ID"
  value       = aws_route_table_association.workload_rt_association[*].route_table_id
}
