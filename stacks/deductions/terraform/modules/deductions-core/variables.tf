variable "region" {
  type    = string
  default = "eu-west-2"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "repo_name" {
  type    = string
  default = "orphaned-record-continuity-infrastructure"
}

variable "component_name" {
  type    = string
  default = "deductions-core"
}

variable "cidr" {}

variable "private_subnets" {
  type = list(any)
}

variable "database_subnets" {
  type = list(any)
}

variable "azs" {
  type = list(any)
}

variable "gocd_cidr" {}

variable "gocd_environment" {}

variable "deductions_private_cidr" {}

variable "core_private_vpc_peering_connection_id" {}

variable "deploy_cross_account_vpc_peering" {}
