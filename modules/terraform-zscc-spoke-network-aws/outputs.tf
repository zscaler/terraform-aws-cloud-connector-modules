output "vpc_id" {
  description = "VPC ID"
  value       = try(data.aws_vpc.vpc_selected[0].id, aws_vpc.vpc[0].id)
}

output "workload_subnet_ids" {
  description = "Workloads Subnet ID"
  value       = aws_subnet.workload_subnet[*].id
}

output "workload_route_table_ids" {
  description = "Workloads Route Table ID"
  value       = aws_route_table_association.workload_rt_association[*].route_table_id
}

output "public_subnet_ids" {
  description = "Public Subnet ID"
  value       = aws_subnet.public_subnet[*].id
}