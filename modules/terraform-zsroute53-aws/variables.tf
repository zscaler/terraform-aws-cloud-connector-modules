variable "name_prefix" {
  description = "A prefix to associate to all the Cloud Connector module resources"
  default     = "zscaler-cc"
}

variable "resource_tag" {
  description = "A tag to associate to all the Cloud Connector module resources"
  default     = "cloud-connector"
}

variable "vpc" {
  description = "VPC id for the Route53 Endpoint"
}

variable "r53_subnet_ids" {
  description = "Subnet IDs for the Route53 Endpoint"
}

variable "domain_names" {
  type        = map(map(string))
  description = "Domain names fqdn/wildcard to have Route 53 redirect DNS requests to Cloud Connector for ZPA. Refer to terraform.tfvars step 10"
}

variable "target_address" {
  type        = list(string)
  description = "Route 53 DNS queries will be forwarded to these Zscaler Global VIP addresses"
  default     = ["185.46.212.88" , "185.46.212.89"]
}

variable "global_tags" {
  description = "populate custom user provided tags"
}

variable "zscaler_domains" {
  type            = map(map(string))
  description     = "Domains that Route 53 should not forward to Cloud Connector"
  
  default = {
  ZS-FreeBSD      = { domain_name = "freebsd.org" }
  ZS-NTP          = { domain_name = "ntp.org" }
  ZS-Zscaler      = { domain_name = "zscaler.com" }
  ZS-Zpath        = { domain_name = "zpath.net" }
  ZS-ZPAGov       = { domain_name = "zpagov.net" }
  ZS-ZPABeta      = { domain_name = "zpabeta.net" }
  ZS-ZscalerBeta  = { domain_name = "zscalerbeta.net" }
  ZS-ZsNet        = { domain_name = "zscaler.net" }
  ZS-ZscalerOne   = { domain_name = "zscalerone.net" }
  ZS-ZscalerTwo   = { domain_name = "zscalertwo.net" }
  ZS-ZscalerThree = { domain_name = "zscalerthree.net" }
  ZS-ZsCloud      = { domain_name = "zscloud.net" }
  ZS-ZscalerGov   = { domain_name = "zscalergov.net" }
  }
}