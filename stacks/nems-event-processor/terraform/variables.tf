variable "region" {
  type    = string
  default = "eu-west-2"
}

variable "repo_name" {
  type = string
  default = "prm-deductions-nems-event-processor"
}

variable "environment" {}

variable "component_name" {
  default = "nems-event-processor"
}

variable "dns_name" {
  default = "nems-event-processor"
}

variable "task_image_tag" {}

variable "task_cpu" {
  default = 512
}
variable "task_memory" {
  default = 1024
}

variable "service_desired_count" {
  default = 1
}

variable "log_level" {
  type = string
  default = "debug"
}

variable "re_registration_sns_topic_cross_account_subscriber_account_ids" {
  type = list(string)
  default = []
}