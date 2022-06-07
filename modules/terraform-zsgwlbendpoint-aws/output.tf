output "gwlbe" {
  value = aws_vpc_endpoint.gwlb-vpce.*.id
}