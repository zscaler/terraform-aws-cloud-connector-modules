terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.10.0, < 7.0.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.2.0, < 2.6"
    }
  }
  required_version = ">= 0.13.7, < 2.0.0"
}
