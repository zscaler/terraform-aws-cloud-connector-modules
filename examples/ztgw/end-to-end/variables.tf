# -----------------------------------------------------------------------------
# examples/aws-end-to-end — inputs
# -----------------------------------------------------------------------------

# --- Customer AWS Environment -------------------------------------------------
variable "aws_region" {
  description = "Target AWS region for the ZTGW and consumer VPC (e.g. us-west-2)."
  type        = string
  default     = "us-west-2"
}

variable "customer_aws_account_id" {
  description = "The 12-digit AWS Account ID where the customer VPC resides (whitelisted on the ZTGW Endpoint Service)."
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.customer_aws_account_id))
    error_message = "customer_aws_account_id must be a 12-digit numeric AWS Account ID."
  }
}

variable "customer_vpc_id" {
  description = "The existing customer VPC ID where the GWLB endpoint should be deployed."
  type        = string
  default     = ""
}

variable "endpoint_subnet_ids" {
  description = "Subnet IDs in the customer VPC where the Gateway Load Balancer endpoint interfaces will be placed (minimum 1 per AZ)."
  type        = list(string)
  default     = []
}

variable "workload_route_table_ids" {
  description = "Route Table IDs associated with customer workload subnets whose egress traffic should route to ZTGW."
  type        = list(string)
  default     = []
}

variable "intercept_cidr_block" {
  description = "Traffic destination to route into ZTGW (0.0.0.0/0 for all internet/outbound egress)."
  type        = string
  default     = "0.0.0.0/0"
}

variable "deploy_key" {
  description = "Prefix for tagging customer-side AWS resources (e.g. ztgw-aws)."
  type        = string
  default     = "ztgw-aws"
}

# --- Zscaler OneAPI Credentials & Gateway Settings ---------------------------
variable "client_id" {
  description = "Zscaler OneAPI / Zidentity Client ID."
  type        = string
  default     = ""
}

variable "client_secret" {
  description = "Zscaler OneAPI / Zidentity Client Secret."
  type        = string
  sensitive   = true
  default     = ""
}

variable "vanity_domain" {
  description = "Zscaler tenant vanity domain (e.g. acme for acme.zslogin.net)."
  type        = string
  default     = ""
}

variable "cloud" {
  description = "Zscaler cloud environment (zscaler, zscalerbeta, zscalerone, zscalertwo, zscalerthree)."
  type        = string
  default     = "zscaler"
}

variable "login_domain" {
  description = "Optional custom login domain override (defaults to cloud-derived domain, e.g. zslogin.net)."
  type        = string
  default     = ""
}

variable "gateway_name" {
  description = "Descriptive name for the ZTGW in the Zscaler portal (e.g. aws-ztgw-us-west-2)."
  type        = string
  default     = "aws-ztgw"
}

variable "location_name" {
  description = "Descriptive location name registered in Zscaler cloud. Must start with 'Unified' for AWS."
  type        = string
  default     = null
}

variable "availability_zones" {
  description = "List of availability zones in the target region (minimum 2 zones for HA)."
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b"]
}

variable "insecure_skip_verify" {
  description = "Skip SSL certificate verification for Zscaler OneAPI calls (useful in environments with corporate SSL inspection/proxies)."
  type        = bool
  default     = false
}

# --- Deployment Mode Toggles ------------------------------------------------
variable "deploy_ztgw" {
  description = "Whether to provision the ZTGW on the Zscaler side (set to false for consumer-only mode)."
  type        = bool
  default     = true
}

variable "deploy_consumer" {
  description = "Whether to deploy the consumer-side VPC plumbing (set to false for gateway-only mode)."
  type        = bool
  default     = true
}

variable "endpoint_service_name" {
  description = "Existing Gateway Load Balancer Endpoint Service name (required if deploy_ztgw = false in consumer-only mode)."
  type        = string
  default     = null
}

variable "auto_activate_pending" {
  description = "Whether to automatically activate pending tenant changes from other admin sessions if required to create the ZTGW."
  type        = bool
  default     = false
}

variable "overwrite_existing_routes" {
  description = "Whether to automatically overwrite/replace existing conflicting routes in the workload route tables."
  type        = bool
  default     = true
}




