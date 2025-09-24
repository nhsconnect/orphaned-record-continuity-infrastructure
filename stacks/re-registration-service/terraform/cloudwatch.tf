locals {
  re_registration_service_metric_namespace = "ReRegistrationService"
  error_logs_metric_name              = "ErrorCountInLogs"
  sqs_namespace = "AWS/SQS"
}

resource "aws_cloudwatch_log_group" "log_group" {
  name = "/nhs/deductions/${var.environment}-${data.aws_caller_identity.current.account_id}/${var.component_name}"

  tags = {
    Environment = var.environment
    CreatedBy= var.repo_name
  }
}

resource "aws_cloudwatch_metric_alarm" "health_metric_failure_alarm" {
  alarm_name                = "${var.environment}-${var.component_name}-health-metric-failure"
  comparison_operator       = "LessThanThreshold"
  threshold                 = "1"
  evaluation_periods        = "3"
  metric_name               = "Health"
  namespace                 = local.re_registration_service_metric_namespace
  alarm_description         = "Alarm to flag failed health checks"
  statistic                 = "Maximum"
  treat_missing_data        = "breaching"
  period                    = "60"
  dimensions = {
    "Environment" = var.environment
  }
  alarm_actions             = [data.aws_sns_topic.alarm_notifications.arn]
  ok_actions                = [data.aws_sns_topic.alarm_notifications.arn]
}
resource "aws_cloudwatch_log_metric_filter" "log_metric_filter" {
  name           = "${var.environment}-${var.component_name}-error-logs"
  pattern        = "{ $.level = \"ERROR\" }"
  log_group_name = aws_cloudwatch_log_group.log_group.name

  metric_transformation {
    name          = local.error_logs_metric_name
    namespace     = local.re_registration_service_metric_namespace
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
  namespace           = local.re_registration_service_metric_namespace
  statistic           = "Sum"
  alarm_description   = "This alarm monitors errors logs in ${var.component_name}"
  treat_missing_data  = "notBreaching"
  actions_enabled     = "true"
  alarm_actions       = [data.aws_sns_topic.alarm_notifications.arn]
  ok_actions          = [data.aws_sns_topic.alarm_notifications.arn]
}

resource "aws_cloudwatch_metric_alarm" "re_registrations_age_of_message" {
  alarm_name          = "${var.environment}-${var.component_name}-approx-age-of-oldest-message"
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.threshold_approx_age_oldest_message
  evaluation_periods  = "1"
  metric_name         = "ApproximateAgeOfOldestMessage"
  namespace           = local.sqs_namespace
  alarm_description   = "Alarm to alert approximate time for message in the queue"
  statistic           = "Maximum"
  period              = var.period_of_age_of_message_metric
  dimensions          = {
    QueueName = aws_sqs_queue.re_registrations.name
  }
  alarm_actions       = [data.aws_sns_topic.alarm_notifications.arn]
  ok_actions          = [data.aws_sns_topic.alarm_notifications.arn]
}