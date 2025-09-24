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

variable "gocd_environment" {
  default     = "prod"
}

variable "component_name" {
  type        = string
  default     = "deductions-private"
}

variable "cidr" {}

variable "gocd_cidr" {}

variable "deductions_core_cidr" {}

variable "public_subnets" {
  type = list
}

variable "private_subnets" {
  type = list
}

variable "database_subnets" {
  type = list
}

variable "azs" {
  type = list
}

variable "pds_deregistration_delay" {
  default = 15
}

# deductions-public mq variables
variable "broker_name" {
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

variable "mq_deployment_mode" {
  type = string
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

variable "vpn_client_subnet" {}

variable "core_private_vpc_peering_connection_id" {}
variable "repo_mhs_vpc_cidr_block" {}
variable "test_harness_mhs_vpc_cidr_block" {}
variable "repo_mhs_vpc_peering_connection_id" {}
variable "test_harness_mhs_vpc_peering_connection_id" {}
variable "deploy_mhs_test_harness" {}
variable "environment_public_zone" {}
variable "environment_private_zone" {}

variable "deploy_cross_account_vpc_peering"{}

variable "grant_access_to_queues_through_vpn" {}