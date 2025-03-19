output "vpc_id" {
  description = "VPC ID"
  value       = try(data.aws_vpc.vpc_selected[0].id, aws_vpc.vpc[0].id)
}

output "cc_subnet_ids" {
  description = "Cloud Connector Subnet ID"
  value       = var.byo_subnets ? data.aws_subnet.cc_subnet_selected[*].id : aws_subnet.cc_subnet[*].id
}

output "zs_subnet_az_names" {
  description = "Zscaler Subnet Availability Zone Names"
  value       = var.byo_subnets ? data.aws_subnet.cc_subnet_selected[*].availability_zone : aws_subnet.cc_subnet[*].availability_zone
}
output "zs_subnet_az_ids" {
  description = "Zscaler Subnet Availability Zone IDs"
  value       = var.byo_subnets ? data.aws_subnet.cc_subnet_selected[*].availability_zone_id : aws_subnet.cc_subnet[*].availability_zone_id
}
output "zs_subnet_cidrs" {
  description = "Zscaler Subnet CIDR blocks"
  value       = var.byo_subnets ? data.aws_subnet.cc_subnet_selected[*].cidr_block : aws_subnet.cc_subnet[*].cidr_block
}

output "workload_subnet_ids" {
  description = "Workloads Subnet ID"
  value       = aws_subnet.workload_subnet[*].id
}

output "workload_subnet_cidrs" {
  description = "Workloads Subnet CIDR blocks"
  value       = aws_subnet.workload_subnet[*].cidr_block
}

output "workload_subnet_az_names" {
  description = "Workload Subnet Availability Zone Names"
  value       = aws_subnet.workload_subnet[*].availability_zone
}
output "workload_subnet_az_ids" {
  description = "Workload Subnet Availability Zone IDs"
  value       = aws_subnet.workload_subnet[*].availability_zone_id
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
  value       = var.byo_ngw ? data.aws_nat_gateway.ngw_selected[*].public_ip : aws_nat_gateway.ngw[*].public_ip
}

output "workload_route_table_ids" {
  description = "Workloads Route Table ID"
  value       = aws_route_table_association.workload_rt_association[*].route_table_id
}
