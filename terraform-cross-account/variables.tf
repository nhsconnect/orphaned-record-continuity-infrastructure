variable "state_bucket_infix" {}
variable "max_images_per_repo" {
  description = "Max number of tagged images to retain"
  type        = number
  default     = 30
}

variable "untagged_expire_days" {
  description = "Days after which untagged images expire"
  type        = number
  default     = 7
}

variable "repo_name" {
  default = "prm-deductions-infra"
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
variable "component_name"   { 
  type = string 
  }
variable "default_tags"     { 
  type = map(string)
  default = {} 
 }
variable "attach_policy_to_role_name" { 
  type = string
  default = "" 
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

# remote-state wiring for the VPC project
variable "vpc_state_bucket"      { type = string }
variable "vpc_state_key"         { type = string }          # e.g. "network/terraform.tfstate"
variable "vpc_state_lock_table"  { type = string }          # DynamoDB lock table name
