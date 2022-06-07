terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version  = "~> 4.2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 2.2"
    }
    local = {
      source = "hashicorp/local"
    }
    null = {
      source = "hashicorp/null"
    }
  }
  required_version = ">= 0.13"
}
