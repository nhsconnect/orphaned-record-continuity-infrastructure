variable "region" {
  type    = string
  default = "eu-west-2"
}

variable "repo_name" {
  type    = string
  default = "prm-deductions-gp2gp-messenger"
}

variable "environment" {}

variable "component_name" {}
variable "dns_name" {}
variable "task_image_tag" {}
variable "task_cpu" {}
variable "task_memory" {}
variable "port" {}

variable "service_desired_count" {}

variable "alb_deregistration_delay" {}

variable "log_level" {
  type    = string
  default = "debug"
}

variable "grant_access_through_vpn" {}
variable "allow_vpn_to_ecs_tasks" { default = false }

variable "spine_org_code" {}

variable "request_ehr_only_for_safe_listed_ods_codes" {
  default = false
}