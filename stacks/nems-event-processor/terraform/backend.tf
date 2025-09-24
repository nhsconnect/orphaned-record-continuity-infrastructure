terraform{
      backend "s3" {
        bucket = "prm-deductions-terraform-state"
        key    = "nems-event-processor/terraform.tfstate"
        region = "eu-west-2"
        encrypt = true
    }
}
