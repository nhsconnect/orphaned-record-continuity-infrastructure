locals {
  error_logs_metric_name              = "ErrorCountInLogs"
  suspension_service_metric_namespace = var.metric_namespace
  not_suspended_sns_topic_name        = "${var.environment}-suspension-service-not-suspended-sns-topic"
  sns_topic_namespace                 = "AWS/SNS"
  sqs_namespace                       = "AWS/SQS"
  sns_topic_error_logs_metric_name    = "NumberOfNotificationsFailed"
}

resource "aws_cloudwatch_log_group" "log_group" {
  name = "/nhs/deductions/${var.environment}-${data.aws_caller_identity.current.account_id}/${var.component_name}"

  tags = {
    Environment = var.environment
    CreatedBy   = var.repo_name
  }
}

resource "aws_cloudwatch_log_metric_filter" "log_metric_filter" {
  name           = "${var.environment}-${var.component_name}-error-logs"
  pattern        = "{ $.level = \"ERROR\" }"
  log_group_name = aws_cloudwatch_log_group.log_group.name

  metric_transformation {
    name          = local.error_logs_metric_name
    namespace     = local.suspension_service_metric_namespace
    value         = 1
    default_value = 0
  }
}

resource "aws_cloudwatch_metric_alarm" "error_log_alarm" {
  alarm_name          = "${var.environment}-${var.component_name}-error-logs"
  comparison_operator = "GreaterThanThreshold"
  threshold           = "0"
  evaluation_periods  = "1"
  period              = "60"
  metric_name         = local.error_logs_metric_name
  namespace           = local.suspension_service_metric_namespace
  statistic           = "Sum"
  alarm_description   = "This alarm monitors errors logs in ${var.component_name}"
  treat_missing_data  = "notBreaching"
  actions_enabled     = "true"
  alarm_actions       = [data.aws_sns_topic.alarm_notifications.arn]
  ok_actions          = [data.aws_sns_topic.alarm_notifications.arn]
}

resource "aws_cloudwatch_metric_alarm" "not_suspended_sns_topic_error_log_alarm" {
  alarm_name          = "${local.not_suspended_sns_topic_name}-error-logs"
  comparison_operator = "GreaterThanThreshold"
  threshold           = "0"
  evaluation_periods  = "1"
  period              = "60"
  metric_name         = local.sns_topic_error_logs_metric_name
  namespace           = local.sns_topic_namespace
  dimensions = {
    TopicName = local.not_suspended_sns_topic_name
  }
  statistic          = "Sum"
  alarm_description  = "This alarm monitors errors logs in ${local.not_suspended_sns_topic_name}"
  treat_missing_data = "notBreaching"
  actions_enabled    = "true"
  alarm_actions      = [data.aws_sns_topic.alarm_notifications.arn]
  ok_actions         = [data.aws_sns_topic.alarm_notifications.arn]
}

resource "aws_cloudwatch_metric_alarm" "suspension_out_of_order_audit" {
  alarm_name          = "${var.environment}-${var.component_name}-out-of-order-audit"
  comparison_operator = "GreaterThanThreshold"
  threshold           = "900"
  evaluation_periods  = "1"
  metric_name         = "ApproximateAgeOfOldestMessage"
  namespace           = local.sqs_namespace
  alarm_description   = "This alarm triggers when messages on the out of order audit queue is not polled by splunk in last 15 mins"
  statistic           = "Maximum"
  period              = "900"
  dimensions = {
    QueueName = aws_sqs_queue.event_out_of_order_audit.name
  }
  alarm_actions = [data.aws_sns_topic.alarm_notifications.arn]
  ok_actions    = [data.aws_sns_topic.alarm_notifications.arn]
}

resource "aws_cloudwatch_metric_alarm" "suspension_not_suspended_audit" {
  alarm_name          = "${var.environment}-${var.component_name}-not-suspended-audit"
  comparison_operator = "GreaterThanThreshold"
  threshold           = "900"
  evaluation_periods  = "1"
  metric_name         = "ApproximateAgeOfOldestMessage"
  namespace           = local.sqs_namespace
  alarm_description   = "This alarm triggers when messages on the not suspended audit queue is not polled by splunk in last 15 mins"
  statistic           = "Maximum"
  period              = "900"
  dimensions = {
    QueueName = aws_sqs_queue.not_suspended_audit.name
  }
  alarm_actions = [data.aws_sns_topic.alarm_notifications.arn]
  ok_actions    = [data.aws_sns_topic.alarm_notifications.arn]
}

resource "aws_cloudwatch_metric_alarm" "suspension_mof_not_updated_audit" {
  alarm_name          = "${var.environment}-${var.component_name}-mof-not-updated-audit"
  comparison_operator = "GreaterThanThreshold"
  threshold           = "900"
  evaluation_periods  = "1"
  metric_name         = "ApproximateAgeOfOldestMessage"
  namespace           = local.sqs_namespace
  alarm_description   = "This alarm triggers when messages on the MOF not updated audit queue is not polled by splunk in last 15 mins"
  statistic           = "Maximum"
  period              = "900"
  dimensions = {
    QueueName = aws_sqs_queue.mof_not_updated_audit.name
  }
  alarm_actions = [data.aws_sns_topic.alarm_notifications.arn]
  ok_actions    = [data.aws_sns_topic.alarm_notifications.arn]
}

resource "aws_cloudwatch_metric_alarm" "suspension_mof_updated_audit" {
  alarm_name          = "${var.environment}-${var.component_name}-mof-updated-audit"
  comparison_operator = "GreaterThanThreshold"
  threshold           = "900"
  evaluation_periods  = "1"
  metric_name         = "ApproximateAgeOfOldestMessage"
  namespace           = local.sqs_namespace
  alarm_description   = "This alarm triggers when messages on the MOF updated audit queue is not polled by splunk in last 15 mins"
  statistic           = "Maximum"
  period              = "900"
  dimensions = {
    QueueName = aws_sqs_queue.mof_updated_audit.name
  }
  alarm_actions = [data.aws_sns_topic.alarm_notifications.arn]
  ok_actions    = [data.aws_sns_topic.alarm_notifications.arn]
}

resource "aws_cloudwatch_metric_alarm" "suspension_deceased_patient_audit" {
  alarm_name          = "${var.environment}-${var.component_name}-deceased-patient-audit"
  comparison_operator = "GreaterThanThreshold"
  threshold           = "900"
  evaluation_periods  = "1"
  metric_name         = "ApproximateAgeOfOldestMessage"
  namespace           = local.sqs_namespace
  alarm_description   = "This alarm triggers when messages on the deceased patient audit queue is not polled by splunk in last 15 mins"
  statistic           = "Maximum"
  period              = "900"
  dimensions = {
    QueueName = aws_sqs_queue.deceased_patient_audit.name
  }
  alarm_actions = [data.aws_sns_topic.alarm_notifications.arn]
  ok_actions    = [data.aws_sns_topic.alarm_notifications.arn]
}

resource "aws_cloudwatch_metric_alarm" "suspension_invalid_suspension_dlq_audit" {
  alarm_name          = "${var.environment}-${var.component_name}-invalid-suspension-dlq-audit"
  comparison_operator = "GreaterThanThreshold"
  threshold           = "900"
  evaluation_periods  = "1"
  metric_name         = "ApproximateAgeOfOldestMessage"
  namespace           = local.sqs_namespace
  alarm_description   = "This alarm triggers when messages on the invalid suspensions dlq audit queue is not polled by splunk in last 15 mins"
  statistic           = "Maximum"
  period              = "900"
  dimensions = {
    QueueName = aws_sqs_queue.invalid_suspension_audit.name
  }
  alarm_actions = [data.aws_sns_topic.alarm_notifications.arn]
  ok_actions    = [data.aws_sns_topic.alarm_notifications.arn]
}
