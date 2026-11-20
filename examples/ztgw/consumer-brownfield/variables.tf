# ==============================================================================
# examples/aws/consumer-brownfield — variables
# ==============================================================================

variable "aws_region" {
  description = "Target AWS region for the consumer VPC (e.g. us-east-1)."
  type        = string
  default     = "us-east-1"
}

variable "customer_vpc_id" {
  description = "The ID of the existing customer VPC to connect (e.g. vpc-0123456789abcdef0)."
  type        = string
}

variable "endpoint_service_name" {
  description = "The AWS Gateway Load Balancer Endpoint Service name (provided by InfoSec / Zscaler)."
  type        = string
}

variable "endpoint_subnet_ids" {
  description = "Subnet IDs in the customer VPC where the GWLB endpoint interface will be placed (minimum 1 per AZ, in supported zones)."
  type        = list(string)
}

variable "workload_route_table_ids" {
  description = "Route Table IDs to steer default outbound traffic (0.0.0.0/0) into ZTGW."
  type        = list(string)
  default     = []
}

variable "intercept_cidr_block" {
  description = "Destination CIDR block to route to ZTGW (default: 0.0.0.0/0 for all internet egress)."
  type        = string
  default     = "0.0.0.0/0"
}

variable "overwrite_existing_routes" {
  description = "Automatically clear conflicting default routes (e.g. to IGW) before attaching ZTGW."
  type        = bool
  default     = true
}

variable "deploy_key" {
  description = "Resource prefix tag for naming."
  type        = string
  default     = "ztgw-aws"
}
