# -----------------------------------------------------------------------------
# modules/gateway — inputs (Zscaler OneAPI)
# -----------------------------------------------------------------------------

# --- Zscaler OneAPI / Zidentity Credentials ----------------------------------
variable "client_id" {
  description = "Zscaler OneAPI / Zidentity Client ID."
  type        = string
}

variable "client_secret" {
  description = "Zscaler OneAPI / Zidentity Client Secret."
  type        = string
  sensitive   = true
}

variable "vanity_domain" {
  description = "Zscaler tenant vanity domain (e.g. acme for acme.zslogin.net)."
  type        = string
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

# --- Gateway Configuration --------------------------------------------------
variable "gateway_name" {
  description = "Descriptive name for the ZTGW in the Zscaler portal (e.g. gcp-ztgw-us-central1)."
  type        = string
  default     = "gcp-ztgw"
}

variable "platform" {
  description = "Cloud platform type: GCP or AWS."
  type        = string
  default     = "GCP"

  validation {
    condition     = contains(["GCP", "AWS"], upper(var.platform))
    error_message = "Platform must be either 'GCP' or 'AWS'."
  }
}

variable "region" {
  description = "Target cloud region for the ZTGW (e.g. us-central1 for GCP, us-west-2 for AWS)."
  type        = string
}

variable "availability_zones" {
  description = "List of availability zones in the target region (minimum 2 zones for HA)."
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "At least two availability zones must be specified for high availability."
  }
}

variable "location_name" {
  description = "Descriptive location name registered in the Zscaler cloud. Defaults to Unified-<platform>-<region>."
  type        = string
  default     = null
}

variable "allowlist_projects" {
  description = "List of customer cloud accounts/projects permitted to attach to the ZTGW (GCP project IDs or AWS account IDs)."
  type        = list(string)
  default     = []
}

variable "iam_principal_email" {
  description = "Optional IAM user/service-account principal email for the gateway provisioning data."
  type        = string
  default     = ""
}

variable "poll_timeout_minutes" {
  description = "Maximum time in minutes to wait for the ZTGW deployment to become healthy."
  type        = number
  default     = 10
}

variable "poll_interval_seconds" {
  description = "Interval in seconds between deployment status polling checks."
  type        = number
  default     = 15
}

variable "insecure_skip_verify" {
  description = "Skip SSL certificate verification for Zscaler OneAPI calls (useful in environments with corporate SSL inspection/proxies)."
  type        = bool
  default     = false
}

variable "metadata_path" {
  description = "Optional path where the gateway metadata JSON state should be saved (defaults to $${path.root}/.ztgw-state-<gateway_name>.json)."
  type        = string
  default     = null
}

variable "auto_activate_pending" {
  description = "Whether to automatically activate pending tenant changes from other admin sessions if required to create the ZTGW (defaults to false to prevent unreviewed changes from being published)."
  type        = bool
  default     = false
}


