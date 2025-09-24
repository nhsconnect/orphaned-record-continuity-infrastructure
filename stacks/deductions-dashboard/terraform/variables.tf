variable "state_bucket_infix" {}

variable "repo_name" {
  default = "prm-deductions-infra"
}

variable "region" {
  default = "eu-west-2"
}

variable "environment" {
  type = string
}
