locals {
  error_logs_metric_name        = "ErrorCountInLogs"
  mhs_inbound_metric_namespace  = "MhsInbound"
  mhs_outbound_metric_namespace = "MhsOutbound"
}

resource "aws_cloudwatch_log_metric_filter" "mhs_inbound_log_metric_filter" {
  name           = "${var.environment}-mhs-inbound-error-logs"
  pattern        = "{ $.level = \"ERROR\" }"
  log_group_name = aws_cloudwatch_log_group.mhs_inbound_log_group.name

  metric_transformation {
    name          = local.error_logs_metric_name
    namespace     = local.mhs_inbound_metric_namespace
    value         = 1
    default_value = 0
  }
}

resource "aws_cloudwatch_log_metric_filter" "mhs_outbound_log_metric_filter" {
  name           = "${var.environment}-mhs-outbound-error-logs"
  pattern        = "{ $.level = \"ERROR\" }"
  log_group_name = aws_cloudwatch_log_group.mhs_outbound_log_group.name

  metric_transformation {
    name          = local.error_logs_metric_name
    namespace     = local.mhs_outbound_metric_namespace
    value         = 1
    default_value = 0
  }
}

resource "aws_cloudwatch_log_group" "mhs_inbound_log_group" {
  name = "/ecs/${var.environment}-${var.cluster_name}-mhs-inbound"
  tags = {
    Name        = "${var.environment}-${var.cluster_name}-mhs-inbound-log-group"
    Environment = var.environment
    CreatedBy   = var.repo_name
  }
}

resource "aws_cloudwatch_log_group" "mhs_outbound_log_group" {
  name = "/ecs/${var.environment}-${var.cluster_name}-mhs-outbound"
  tags = {
    Name        = "${var.environment}-${var.cluster_name}-mhs-outbound-log-group"
    Environment = var.environment
    CreatedBy   = var.repo_name
  }
}

resource "aws_cloudwatch_metric_alarm" "inbound_nlb_down_errors" {
  alarm_name          = "${var.repo_name} service down"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/NetworkELB"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "This metric monitors the health of ${var.repo_name}"
  treat_missing_data  = "breaching"
  datapoints_to_alarm = "1"
  dimensions = {
    TargetGroup  = aws_lb_target_group.inbound_https_nlb_target_group.arn_suffix
    LoadBalancer = aws_lb.public_inbound_nlb.arn_suffix
  }
  alarm_actions = [data.aws_sns_topic.alarm_notifications.arn]
}

resource "aws_cloudwatch_metric_alarm" "outbound_alb_down_errors" {
  alarm_name          = "${var.repo_name} service down"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "This metric monitors the health of ${var.repo_name}"
  treat_missing_data  = "breaching"
  datapoints_to_alarm = "1"
  dimensions = {
    TargetGroup  = aws_lb_target_group.outbound_alb_target_group.arn_suffix
    LoadBalancer = aws_alb.outbound_alb.arn_suffix
  }
  alarm_actions = [data.aws_sns_topic.alarm_notifications.arn]
}

data "aws_sns_topic" "alarm_notifications" {
  name = "${var.environment}-alarm-notifications-sns-topic"
}

resource "aws_cloudwatch_metric_alarm" "approx_active_mq_message_processing_broker_1" {
  alarm_name          = "${var.environment}-inbound-queue-broker-1-message-processing"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 0
  evaluation_periods  = "1"
  metric_name         = "QueueSize"
  namespace           = "AWS/AmazonMQ"
  alarm_description   = "Alarm to alert approximate time for message in the queue"
  statistic           = "Maximum"
  period              = 1800
  dimensions = {
    Broker = "${data.aws_ssm_parameter.mq_broker_name.value}-1"
    Queue  = "inbound"
  }
  alarm_actions = [data.aws_sns_topic.alarm_notifications.arn]
  ok_actions    = [data.aws_sns_topic.alarm_notifications.arn]
}

resource "aws_cloudwatch_metric_alarm" "approx_active_mq_message_processing_broker_2" {
  alarm_name          = "${var.environment}-inbound-queue-broker-2-message-processing"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 0
  evaluation_periods  = "1"
  metric_name         = "QueueSize"
  namespace           = "AWS/AmazonMQ"
  alarm_description   = "Alarm to alert approximate time for message in the queue"
  statistic           = "Maximum"
  period              = 1800
  dimensions = {
    Broker = "${data.aws_ssm_parameter.mq_broker_name.value}-1"
    Queue  = "inbound"
  }
  alarm_actions = [data.aws_sns_topic.alarm_notifications.arn]
  ok_actions    = [data.aws_sns_topic.alarm_notifications.arn]
}

data "aws_ssm_parameter" "mq_broker_name" {
  name = "/repo/${var.environment}/output/prm-deductions-infra/broker-name"
}