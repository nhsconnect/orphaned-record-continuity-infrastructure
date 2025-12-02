provider "aws" {
  region    = var.region
}

provider "aws" {
  alias = "ci"
  region  = var.region
  assume_role {
    role_arn     = "arn:aws:iam::${var.common_account_id}:role/${var.common_account_role}"
    session_name = "base-infra-cross-account"
  }
}

terraform{
      backend "s3" {
        bucket  = "prm-deductions-prod-terraform-state"
        key     = "base-infra/terraform.tfstate"
        region  = "eu-west-2"
        encrypt = true
    }
}
