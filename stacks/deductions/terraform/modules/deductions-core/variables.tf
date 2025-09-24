variable "region" {
  type = string
  default = "eu-west-2"
}

variable "environment" {
  type        = string
  default     = "dev"
}

variable "repo_name" {
  type = string
  default = "prm-deductions-infra"
}

variable "component_name" {
  type        = string
  default     = "deductions-core"
}

variable "cidr" {}

variable "private_subnets" {
  type = list
}

variable "database_subnets" {
  type = list
}

variable "azs" {
  type = list
}

variable "deductions_private_cidr" {}
variable "gocd_cidr" {}

variable "core_private_vpc_peering_connection_id" {}

variable "gocd_environment" {}

variable "deploy_cross_account_vpc_peering"{}
