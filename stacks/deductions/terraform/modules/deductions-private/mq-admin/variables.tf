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
  default     = "deductions-private"
}

variable "vpn_sg_id" {}
variable "mq_broker_instances" {}
variable "deductions_private_vpc_private_subnets" {}
variable "deductions_private_vpc_id" {}
variable "environment_public_zone" {}
variable "environment_private_zone" {}
variable "service_to_mq_admin_sg_id" {}
variable "vpc_id" {}