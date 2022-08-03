output "vpc-id" {
  value = data.aws_vpc.vpc-selected.id
}

output "cc-subnet-ids" {
  value = data.aws_subnet.cc-subnet-selected.*.id
}

output "workload-subnet-ids" {
  value = aws_subnet.workload-subnet.*.id
}

output "public-subnet-ids" {
  value = aws_subnet.public-subnet.*.id
}

output "route53-subnet-ids" {
  value = aws_subnet.route53-subnet.*.id
}

output "nat-gateway-ips" {
  value = data.aws_nat_gateway.ngw-selected.*.public_ip
}

output "workload-route-table-ids" {
  value = aws_route_table_association.workload-rt-association.*.route_table_id
}



