variable "region" {
  type    = string
  default = "eu-west-2"
}

variable "environment" {
  type = string
}

variable "repo_name" {
  type    = string
  default = "prm-deductions-infra"
}

variable "my_ip" {
  default = "127.0.0.1"
}

variable "deductions_private_component_name" {
  type = string
}

variable "deductions_core_component_name" {
  type = string
}

variable "deductions_private_cidr" {
  type = string
}

variable "deductions_private_vpn_client_subnet" {
  type = string
}

variable "deductions_private_public_subnets" {
  type = list(any)
}

variable "deductions_private_private_subnets" {
  type = list(any)
}

variable "deductions_private_database_subnets" {
  type = list(any)
}

variable "deductions_private_azs" {
  type = list(any)
}

variable "deductions_core_cidr" {
  type = string
}

variable "deductions_core_private_subnets" {
  type = list(any)
}

variable "deductions_core_database_subnets" {
  type = list(any)
}

variable "deductions_core_azs" {
  type = list(any)
}

variable "gocd_cidr" {}

variable "gocd_environment" {
  default = "prod"
}

# deductions-public mq variables
variable "mq_deployment_mode" {
  type = string
}

variable "apply_immediately" {
  type        = string
  default     = "false"
  description = "Specifies whether any cluster modifications are applied immediately, or during the next maintenance window"
}

variable "auto_minor_version_upgrade" {
  type        = string
  default     = "true"
  description = "Enables automatic upgrades to new minor versions for brokers, as Apache releases the versions"
}

variable "deployment_mode" {
  type        = string
  default     = "ACTIVE_STANDBY_MULTI_AZ"
  description = "The deployment mode of the broker. Supported: SINGLE_INSTANCE and ACTIVE_STANDBY_MULTI_AZ"
}

variable "engine_type" {
  type        = string
  default     = "ActiveMQ"
  description = "The type of broker engine. Currently, Amazon MQ supports only ActiveMQ"
}

variable "engine_version" {
  type        = string
  default     = "5.18.4"
  description = "The version of the broker engine."
}

variable "host_instance_type" {
  type        = string
  default     = "mq.t3.micro"
  description = "The broker's instance type. e.g. mq.t3.micro or mq.m5.large"
}

variable "general_log" {
  type        = string
  default     = "true"
  description = "Enables general logging via CloudWatch"
}

variable "audit_log" {
  type        = string
  default     = "true"
  description = "Enables audit logging. User management action made using JMX or the ActiveMQ Web Console is logged"
}

variable "maintenance_day_of_week" {
  type        = string
  default     = "SUNDAY"
  description = "The maintenance day of the week. e.g. MONDAY, TUESDAY, or WEDNESDAY"
}

variable "maintenance_time_of_day" {
  type        = string
  default     = "03:00"
  description = "The maintenance time, in 24-hour format. e.g. 02:00"
}

variable "maintenance_time_zone" {
  type        = string
  default     = "UTC"
  description = "The maintenance time zone, in either the Country/City format, or the UTC offset format. e.g. CET"
}

variable "state_db_allocated_storage" {}
variable "state_db_engine_version" {}
variable "state_db_instance_class" {}

variable "mhs_vpc_cidr_block" {
  type        = string
  description = "The CIDR block to use for the MHS VPC that is created. Should be a /16 block. Note that this cidr block must not overlap with the cidr blocks of the VPCs that the MHS VPC is to be peered with."
}

variable "mhs_vpc_additional_cidr_block" {
  type        = string
  description = "The additional CIDR block to use for MHS VPC"
  default     = ""
}

variable "mhs_cidr_newbits" {
  description = "Defines the size of the subnets"
}
variable "test_harness_mhs_cluster_domain_name" { default = "" }
variable "repo_mhs_cluster_domain_name" {}
variable "common_account_id" {}
variable "common_account_role" {}
variable "deploy_cross_account_vpc_peering" {}
variable "deploy_mhs_test_harness" {}
variable "deploy_prod_route53_zone" { default = false }
variable "mhs_repo_public_subnets_outbound" {}
variable "mhs_repo_public_subnets_inbound" {}
variable "mhs_repo_private_subnets" {}
variable "mhs_test_harness_public_subnets_outbound" {}
variable "mhs_test_harness_public_subnets_inbound" {}
variable "mhs_test_harness_private_subnets" {}
variable "inbound_sig_ips" {}
variable "grant_access_to_queues_through_vpn" {}
variable "is_restricted_account" {
  default = false
}

variable "alarm_lambda_zip" {
  type        = string
  description = "path to zipfile containing lambda code to dispatch alarm notifications to MS Teams"
  default     = "../notification-lambda/build/alarm.zip"
}

variable "ehr_hard_deletion_lambda_zip" {
  type        = string
  description = "path to zipfile containing lambda code for the ehr-hard-deletion-lambda"
  default     = "../ehr-hard-deletion-lambda/build/ehr-hard-deletion-lambda.zip"
}

variable "generate_cost_report_lambda_zip" {
  type        = string
  description = "path to zip file containing lambda code to schedule cost report"
  default     = "../generate-cost-report-lambda/build/generate-cost-report-lambda.zip"
}

variable "s3_backup_enabled" {
  type        = bool
  default     = false
  description = "Set to true if the environment needs backing up e.g. in production. This will result in versioning and object locking being enabled for select buckets containing critical live data."
}
