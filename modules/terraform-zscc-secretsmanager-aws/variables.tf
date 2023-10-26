variable "name_prefix" {
  type        = string
  description = "A prefix to associate to all the Cloud Connector Secrets Manager module resources"
  default     = null
}

variable "resource_tag" {
  type        = string
  description = "A tag to associate to all the Cloud Connector Secrets Manager module resources"
  default     = null
}

variable "global_tags" {
  type        = map(string)
  description = "Populate any custom user defined tags from a map"
  default     = {}
}

variable "byo_secret" {
  type        = bool
  description = "True/False to conditionally create a new secret. Default is false meaning create a new resource"
  default     = false
}

variable "secret_name" {
  type        = string
  description = "AWS Secrets Manager Secret Name for Cloud Connector provisioning. This could be a new name or existing depending on byo_secret value"
  default     = ""
}

variable "zscaler_username" {
  type        = string
  sensitive   = true
  description = "Zscaler Cloud Connector deploy username. Only required/used if var.byo_secret is false"
}

variable "zscaler_password" {
  type        = string
  sensitive   = true
  description = "Zscaler Cloud Connector deploy password. Only required/used if var.byo_secret is false"
}

variable "zscaler_api_key" {
  type        = string
  sensitive   = true
  description = "Zscaler Cloud Connector API Key. Only required/used if var.byo_secret is false"
}
