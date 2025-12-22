variable "region" {
  type    = string
  default = "eu-west-2"
}

variable "repo_name" {
  type = string
}

variable "environment" {}

variable "component_name" {}

variable "metric_namespace" {}

variable "task_image_tag" {
    type = string
}

variable "task_cpu" {
  default = 512
}
variable "task_memory" {
  default = 1024
}

variable "log_level" {
  type    = string
  default = "debug"
}

variable "process_only_synthetic_patients" {
  default = true
}

variable "repo_process_only_safe_listed_ods_codes" {
  default = true
}

variable "synthetic_patient_prefix" {}

variable "can_update_managing_organisation_to_repo" {
  description = "Toggle to allow updating managing organisation to repo ODS code"
  default     = false
}

variable "is_end_of_transfer_service" {
  type    = bool
  default = false
}

variable "image_name" {
  type    = string
  default = "suspension-service"
}

variable "ecs_desired_count" {
  default = 1
}
