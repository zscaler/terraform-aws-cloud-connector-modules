terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.32"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.2.0, < 2.6"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.1, < 3.3"
    }
  }
  required_version = ">= 0.13.7, < 2.0.0"
}
