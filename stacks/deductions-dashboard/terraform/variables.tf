variable "state_bucket_infix" {}

variable "repo_name" {
  default = "orphaned-record-continuity-infrastructure"
}

variable "region" {
  default = "eu-west-2"
}

variable "environment" {
  type = string
}
