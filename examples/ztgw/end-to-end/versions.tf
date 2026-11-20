terraform {
  required_version = ">= 1.9.0"

  required_providers {
    ztc = {
      source  = "zscaler/ztc"
      version = ">= 0.3.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}
