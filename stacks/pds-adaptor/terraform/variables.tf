variable "region" {
  type    = string
  default = "eu-west-2"
}

variable "repo_name" {
  type    = string
  default = "prm-deductions-pds-adaptor"
}

variable "environment" {}

variable "component_name" {
  default = "pds-adaptor"
}

variable "dns_name" {
  default = "pds-adaptor"
}

variable "task_image_tag" {
  default = "latest"
}

variable "task_cpu" {}
variable "task_memory" {}
variable "port" {}

variable "service_desired_count" {}

variable "alb_deregistration_delay" {}

variable "log_level" {
  type    = string
  default = "debug"
}

variable "grant_access_through_vpn" {
}