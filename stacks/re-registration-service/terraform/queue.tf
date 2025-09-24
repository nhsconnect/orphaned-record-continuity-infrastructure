locals {
  re_registrations_queue_name     = "${var.environment}-${var.component_name}-re-registrations"
  re_registrations_audit_queue_name     = "${var.environment}-${var.component_name}-audit-uploader"
  re_registrations_audit_dlq_name     = "${var.environment}-${var.component_name}-audit-uploader_dlq"
  active_suspensions_queue_name     = "${var.environment}-${var.component_name}-active-suspensions"
  max_retention_period           = 1209600
  thirty_minute_retention_period = 1800
}

resource "aws_sqs_queue" "re_registrations" {
  name                       = local.re_registrations_queue_name
  message_retention_seconds  = local.max_retention_period
  kms_master_key_id          = data.aws_ssm_parameter.re_registrations_kms_key_id.value
  receive_wait_time_seconds  = 20
  visibility_timeout_seconds = 240

  tags = {
    Name        = local.re_registrations_queue_name
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}

resource "aws_sns_topic_subscription" "re_registrations_topic_sub" {
  protocol             = "sqs"
  raw_message_delivery = true
  topic_arn            = data.aws_ssm_parameter.re_registrations_sns_topic_arn.value
  endpoint             = aws_sqs_queue.re_registrations.arn
}


resource "aws_sqs_queue" "re_registration_audit_uploader" {
  name                       = local.re_registrations_audit_queue_name
  message_retention_seconds  = 1209600
  kms_master_key_id = aws_kms_key.re_registration_audit.id

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.re_registration_audit_uploader_dlq.arn
    maxReceiveCount     = 4
  })
  tags = {
    Name = local.re_registrations_audit_queue_name
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}

resource "aws_sqs_queue" "re_registration_audit_uploader_dlq" {
  name                       = local.re_registrations_audit_dlq_name
  message_retention_seconds  = 1209600
  kms_master_key_id = aws_kms_key.re_registration_audit.id


  tags = {
    Name = local.re_registrations_audit_dlq_name
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}

resource "aws_sqs_queue" "active_suspensions" {
  name                       = local.active_suspensions_queue_name
  message_retention_seconds  = local.max_retention_period
  kms_master_key_id          = data.aws_ssm_parameter.active_suspensions_kms_key_id.value
  receive_wait_time_seconds  = 20
  visibility_timeout_seconds = 240

  tags = {
    Name        = local.active_suspensions_queue_name
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}