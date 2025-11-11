terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0" # or pin to a recent 6.x
    }
  }
  backend "s3" {
    encrypt = true
  }
}

provider "aws" {
  region  = var.region
}