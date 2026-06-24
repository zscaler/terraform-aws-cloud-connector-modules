output "tgw_id" {
  description = "Transit Gateway ID"
  value       = aws_ec2_transit_gateway.tgw.id
}

output "tgw_arn" {
  description = "Transit Gateway ARN"
  value       = aws_ec2_transit_gateway.tgw.arn
}

output "hub_attachment_id" {
  description = "TGW VPC Attachment ID for the Hub VPC"
  value       = aws_ec2_transit_gateway_vpc_attachment.hub.id
}

output "spoke_1_attachment_id" {
  description = "TGW VPC Attachment ID for Spoke 1 VPC"
  value       = aws_ec2_transit_gateway_vpc_attachment.spoke_1.id
}

output "spoke_2_attachment_id" {
  description = "TGW VPC Attachment ID for Spoke 2 VPC"
  value       = aws_ec2_transit_gateway_vpc_attachment.spoke_2.id
}

output "spoke_route_table_id" {
  description = "TGW Route Table ID associated to Spoke 1 and Spoke 2 attachments"
  value       = aws_ec2_transit_gateway_route_table.spoke_rt.id
}

output "hub_route_table_id" {
  description = "TGW Route Table ID associated to the Hub attachment"
  value       = aws_ec2_transit_gateway_route_table.hub_rt.id
}
