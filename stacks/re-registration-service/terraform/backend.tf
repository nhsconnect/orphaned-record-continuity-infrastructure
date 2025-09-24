terraform{
      backend "s3" {
        bucket = "prm-deductions-terraform-state"
        key    = "re-registration-service/terraform.tfstate"
        region = "eu-west-2"
        encrypt = true
    }
}
