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
variable "sns_sqs_role_arn" {}
variable "threshold_for_suspensions_queue_age_of_message" {
  description = "An alarm will be raised if any message gets to this many seconds old"
  default     = "86400"
}
variable "period_of_age_of_message_metric" {
  default = "1800"
}
variable "ecs_cluster_name" {}
variable "ecs_service_name" {}
variable "ecs_desired_count" {
  default = 1
}
