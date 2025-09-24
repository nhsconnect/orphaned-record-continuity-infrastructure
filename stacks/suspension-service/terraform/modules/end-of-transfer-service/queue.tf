locals {
  transfer_complete_queue_name                   = "${var.environment}-${var.component_name}-transfer-complete"
  transfer_complete_observability_queue_name     = "${var.environment}-${var.component_name}-transfer-complete-observability"
}

resource "aws_sqs_queue" "transfer_complete" {
  name                       = local.transfer_complete_queue_name
  message_retention_seconds  = 259200
  kms_master_key_id          = data.aws_ssm_parameter.transfer_complete_kms_key.value
  receive_wait_time_seconds  = 20
  visibility_timeout_seconds = 240

  tags = {
    Name        = local.transfer_complete_queue_name
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}

resource "aws_sqs_queue" "transfer_complete_observability" {
  name                       = local.transfer_complete_observability_queue_name
  message_retention_seconds  = 259200
  kms_master_key_id          = data.aws_ssm_parameter.transfer_complete_kms_key.value
  receive_wait_time_seconds  = 20
  visibility_timeout_seconds = 240

  tags = {
    Name        = local.transfer_complete_observability_queue_name
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}

resource "aws_sns_topic_subscription" "transfer_complete_topic" {
  protocol             = "sqs"
  raw_message_delivery = true
  topic_arn            = data.aws_ssm_parameter.transfer_complete_topic_arn.value
  endpoint             = aws_sqs_queue.transfer_complete.arn
}

resource "aws_sns_topic_subscription" "transfer_complete_observability_topic" {
  protocol             = "sqs"
  raw_message_delivery = true
  topic_arn            = data.aws_ssm_parameter.transfer_complete_topic_arn.value
  endpoint             = aws_sqs_queue.transfer_complete_observability.arn
}