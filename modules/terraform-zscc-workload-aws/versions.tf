terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.7.0"
    }
  }
  required_version = ">= 0.13.7, < 2.0.0"
}
