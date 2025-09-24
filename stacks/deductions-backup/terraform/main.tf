provider "aws" {
  region = "eu-west-2"
}

terraform {
  backend "s3" {
    dynamodb_table = "orc-backup-terraform-lock"
    region         = "eu-west-2"
    key            = "backup/terraform.tfstate"
    encrypt        = true
  }
}
