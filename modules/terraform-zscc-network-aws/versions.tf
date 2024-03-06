terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.32.0, <= 5.39.1"
    }
  }
  required_version = ">= 0.13.7, < 2.0.0"
}
