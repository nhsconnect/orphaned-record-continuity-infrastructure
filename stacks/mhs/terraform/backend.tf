terraform {
  backend "s3" {
    key     = "mhs-dev-repo/terraform.tfstate"
    encrypt = true
  }
}
