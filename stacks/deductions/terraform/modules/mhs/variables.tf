variable "environment" {
  type = string
  description = "An ID used to identify the environment being deployed by this configuration. As this is used as a prefix for the names of most resources this should be kept to 20 characters or less."
}

variable "region" {
  type    = string
  default = "eu-west-2"
}

variable "mhs_vpc_cidr_block" {
  type = string
  description = "The CIDR block to use for the MHS VPC that is created. Should be a /16 block. Note that this cidr block must not overlap with the cidr blocks of the VPCs that the MHS VPC is to be peered with."
}

variable "mhs_vpc_additional_cidr_block" {
  type = string
  description = "The additional CIDR block to use for MHS VPC"
}

variable "repo_name" {
  type = string
  default = "prm-deductions-infra"
}

variable "deductions_private_cidr" {}
variable "mhs_private_cidr_blocks" {}
variable "deductions_private_vpc_id" {}
variable "cluster_name" {}
variable "mhs_public_subnets_inbound" {}
variable "mhs_public_subnets_outbound" {}
variable "mhs_cluster_domain_name" {}
variable "gocd_cidr" {}

variable "deploy_cross_account_vpc_peering"{}

variable "inbound_sig_ips" {}