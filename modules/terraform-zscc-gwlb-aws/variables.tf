variable "name_prefix" {
  type        = string
  description = "A prefix to associate to all the GWLB module resources"
  default     = null
}

variable "resource_tag" {
  type        = string
  description = "A tag to associate to all the GWLB module resources"
  default     = null
}

variable "vpc_id" {
  type        = string
  description = "Cloud Connector VPC ID"
}

variable "cc_small_service_ips" {
  type        = list(string)
  description = "Cloud Connector Small instance size service IPs"
  default     = []
}

variable "cc_med_lrg_service_1_ips" {
  type        = list(string)
  description = "Cloud Connector Medium/Large instance size service-1 IPs"
  default     = []
}

variable "cc_med_lrg_service_2_ips" {
  type        = list(string)
  description = "Cloud Connector Medium/Large instance size service-2 IPs"
  default     = []
}

variable "cc_lrg_service_3_ips" {
  type        = list(string)
  description = "Cloud Connector Large instance size service-3 IPs"
  default     = []
}

variable "http_probe_port" {
  type        = number
  description = "Port number for Cloud Connector cloud init to enable listener port for HTTP probe from GWLB Target Group"
  default     = 50000
  validation {
    condition = (
      var.http_probe_port == 80 ||
      (var.http_probe_port >= 1024 && var.http_probe_port <= 65535)
    )
    error_message = "Input http_probe_port must be set to a single value of 80 or any number between 1024-65535."
  }
}

variable "health_check_interval" {
  type        = number
  description = "Interval for GWLB target group health check probing, in seconds, of Cloud Connector targets. Minimum 5 and maximum 300 seconds"
  default     = 10
}

variable "healthy_threshold" {
  type        = number
  description = "The number of successful health checks required before an unhealthy target becomes healthy. Minimum 2 and maximum 10"
  default     = 3
}

variable "unhealthy_threshold" {
  type        = number
  description = "The number of unsuccessful health checks required before an healthy target becomes unhealthy. Minimum 2 and maximum 10"
  default     = 3
}

variable "cross_zone_lb_enabled" {
  type        = bool
  description = "Determines whether GWLB cross zone load balancing should be enabled or not"
  default     = false
}

variable "cc_subnet_ids" {
  type        = list(string)
  description = "Cloud Connector subnet IDs list"
}

variable "global_tags" {
  type        = map(string)
  description = "Populate any custom user defined tags from a map"
  default     = {}
}
variable "cc_instance_size" {
  type        = string
  description = "Cloud Connector instance size as defined in the Connector portal provisioning template"
  default     = "small"
  validation {
    condition = (
      var.cc_instance_size == "small" ||
      var.cc_instance_size == "medium" ||
      var.cc_instance_size == "large"
    )
    error_message = "Input cc_instance_size must be set to an approved cc instance type."
  }
}
