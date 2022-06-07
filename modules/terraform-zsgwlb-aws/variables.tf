variable "name_prefix" {
  description = "A prefix to associate to all the Cloud Connector module resources"
  default     = "zscaler-cc"
}

variable "resource_tag" {
  description = "A tag to associate to all the Cloud Connector module resources"
  default     = "cloud-connector"
}

variable "vpc" {
  description = "Cloud Connector VPC"
}

variable "cc_small_service_ips" {
  description = "Cloud Connector Small instance size service IPs"
}

variable "cc_med_lrg_service_1_ips" {
  description = "Cloud Connector Medium/Large instance size service-1 IPs"
}

variable "cc_med_lrg_service_2_ips" {
  description = "Cloud Connector Medium/Large instance size service-2 IPs"
}

variable "cc_lrg_service_3_ips" {
  description = "Cloud Connector Large instance size service-3 IPs"
}

variable "http_probe_port" {
  description = "port for Cloud Connector cloud init to enable listener port for HTTP probe from LB"
  default = 0
  validation {
          condition     = (
            var.http_probe_port == 0 ||
            var.http_probe_port == 80 ||
          ( var.http_probe_port >= 1024 && var.http_probe_port <= 65535 )
        )
          error_message = "Input http_probe_port must be set to a single value of 80 or any number between 1024-65535."
      }
}

variable "cross_zone_lb_enabled" {
  type = bool
  default = false
}

variable "cc_subnet_ids" {
  description = "Cloud Connector subnet IDs list"
}

variable "global_tags" {
  description = "populate custom user provided tags"
}

variable "interval" {
  description = "default interval for gwlb target group health check probing"
  default     = 10
}

variable "healthy_threshold" {
  description = "default threshold for gwlb target group health check probing to report a target as healthy"
  default     = 3
}

variable "unhealthy_threshold" {
  description = "default threshold for gwlb target group health check probing to report a target as unhealthy"
  default     = 3
}

variable "cc_instance_size" {
  default = "small"
   validation {
          condition     = ( 
            var.cc_instance_size == "small"  ||
            var.cc_instance_size == "medium" ||
            var.cc_instance_size == "large"
          )
          error_message = "Input cc_instance_size must be set to an approved cc instance type."
      }
}


