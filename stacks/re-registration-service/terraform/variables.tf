variable "region" {
  type    = string
  default = "eu-west-2"
}

variable "repo_name" {
  type    = string
  default = "prm-repo-re-registration-service"
}

variable "service_desired_count" {
  default = 1
}

variable "environment" {}

variable "component_name" {
  default = "re-registration-service"
}

variable "task_image_tag" {}

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

variable "toggle_can_send_delete_ehr_request" {
  description = "Toggle to allow sending delete ehr request"
  default     = false
}

variable "period_of_age_of_message_metric" {
  default = "1800"
}

variable "threshold_approx_age_oldest_message" {
  default = "300"
}