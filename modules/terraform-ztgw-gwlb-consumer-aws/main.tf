# -----------------------------------------------------------------------------
# modules/consumer-aws/gwlb-consumer — AWS GWLB Consumer Integration
#
# Attaches customer AWS VPC workloads to the Zscaler ZTGW Gateway Load Balancer
# via an AWS VPC Endpoint (type GatewayLoadBalancer) and configures subnet route tables.
# -----------------------------------------------------------------------------

data "aws_region" "current" {}

# Ensure AWS Endpoint Service cross-account permissions have fully replicated before creating the endpoint interface
resource "terraform_data" "endpoint_service_waiter" {
  triggers_replace = [
    var.endpoint_service_name
  ]

  provisioner "local-exec" {
    command = <<-EOT
      if command -v aws >/dev/null 2>&1; then
        for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30; do
          if aws ec2 describe-vpc-endpoint-services --region ${data.aws_region.current.region} --service-names ${var.endpoint_service_name} >/dev/null 2>&1; then
            exit 0
          fi
          sleep 5
        done
      else
        echo "--> AWS CLI not found in execution environment; pausing 45s for AWS PrivateLink cross-account permissions to propagate..."
        sleep 45
      fi
    EOT
  }
}

resource "aws_vpc_endpoint" "this" {
  for_each          = toset(var.endpoint_subnet_ids)
  vpc_id            = var.vpc_id
  service_name      = var.endpoint_service_name
  vpc_endpoint_type = "GatewayLoadBalancer"
  subnet_ids        = [each.value]

  tags = merge(
    var.tags,
    {
      Name        = length(var.endpoint_subnet_ids) > 1 ? "${var.deploy_key}-gwlbe-${each.value}" : "${var.deploy_key}-gwlbe"
      ManagedBy   = "terraform-zscaler-ztgw"
      Environment = var.deploy_key
    }
  )

  depends_on = [
    terraform_data.endpoint_service_waiter
  ]
}

# Clear any conflicting pre-existing route (e.g. 0.0.0.0/0 to IGW) before creating the ZTGW route
resource "terraform_data" "route_conflict_resolver" {
  for_each = var.overwrite_existing_routes ? toset(var.workload_route_table_ids) : []

  triggers_replace = [
    each.value,
    var.intercept_cidr_block,
    var.endpoint_service_name
  ]

  provisioner "local-exec" {
    command = <<-EOT
      if command -v aws >/dev/null 2>&1; then
        aws ec2 delete-route --route-table-id ${each.value} --destination-cidr-block ${var.intercept_cidr_block} 2>/dev/null || true
      fi
    EOT
  }
}

# Steer outbound/workload traffic to the ZTGW Gateway Load Balancer Endpoint
resource "aws_route" "workload_to_ztgw" {
  for_each = toset(var.workload_route_table_ids)

  route_table_id         = each.value
  destination_cidr_block = var.intercept_cidr_block
  vpc_endpoint_id        = values(aws_vpc_endpoint.this)[0].id

  depends_on = [
    aws_vpc_endpoint.this,
    terraform_data.route_conflict_resolver
  ]
}
