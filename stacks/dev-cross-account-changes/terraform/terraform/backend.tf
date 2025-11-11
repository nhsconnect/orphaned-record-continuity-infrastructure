terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.60.0"
    }
  }

  backend "s3" {
    encrypt = true
  }
}

provider "aws" {
  profile = "default"
  region  = var.region
}