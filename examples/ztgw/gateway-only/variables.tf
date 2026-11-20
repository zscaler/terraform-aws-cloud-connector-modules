# ==============================================================================
# examples/aws/gateway-only — variables
# ==============================================================================

variable "client_id" {
  description = "Zscaler OneAPI Client ID."
  type        = string
}

variable "client_secret" {
  description = "Zscaler OneAPI Client Secret."
  type        = string
  sensitive   = true
}

variable "vanity_domain" {
  description = "Zscaler vanity domain prefix (e.g. acme for acme.zslogin.net)."
  type        = string
}

variable "cloud" {
  description = "Zscaler cloud environment (zscaler, zscalerbeta, zscalerone, zscalertwo, zscalerthree)."
  type        = string
  default     = "zscaler"
}

variable "login_domain" {
  description = "Optional custom login domain override."
  type        = string
  default     = ""
}

variable "gateway_name" {
  description = "Descriptive name for the ZTGW instance."
  type        = string
  default     = "aws-ztgw-gateway"
}

variable "aws_region" {
  description = "Target AWS region for the ZTGW deployment (e.g. us-west-2)."
  type        = string
  default     = "us-west-2"
}

variable "availability_zones" {
  description = "Physical AWS Availability Zones for HA (minimum 2 zones, e.g. ['use1-az1', 'use1-az2'])."
  type        = list(string)
  default     = ["use1-az1", "use1-az2"]
}

variable "location_name" {
  description = "Location name in Zscaler portal (must begin with 'Unified')."
  type        = string
  default     = null
}

variable "customer_aws_account_ids" {
  description = "List of 12-digit AWS Account IDs to whitelist on the GWLB Endpoint Service."
  type        = list(string)
}

variable "insecure_skip_verify" {
  description = "Skip TLS verification for corporate inspection / ZCC environments."
  type        = bool
  default     = false
}

variable "auto_activate_pending" {
  description = "Automatically activate pending changes in Zscaler cloud."
  type        = bool
  default     = true
}
