variable "state_bucket_infix" {}

variable "repo_name" {
  default = "orphaned-record-continuity-infrastructure"
}

variable "region" {
  default = "eu-west-2"
}

variable "provision_ci_account" {}

variable "provision_strict_iam_roles" {}

variable "environment" {
  type = string
}

variable "immutable_ecr_repositories" {
  type = bool
}

variable "dockerhub_username" {
  type = string
  sensitive = true
}
variable "dockerhub_access_token" {
  type = string
  sensitive = true
}
# lifecycle tuning
variable "max_images_per_repo"   { 
  type = number
  default = 30 
 }
variable "untagged_expire_days"  { 
  type = number
  default = 7 
}
variable "immutable_ecr_repositories" {
  type = bool
}