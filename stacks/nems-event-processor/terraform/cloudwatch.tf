locals {
  error_logs_metric_name                = "ErrorCountInLogs"
  nems_event_processor_metric_namespace = "NemsEventProcessor"
  suspensions_sns_topic_name            = "${var.environment}-nems-event-processor-suspensions-sns-topic"
  unhandled_events_sns_topic_name       = "${var.environment}-nems-event-processor-unhandled-events-sns-topic"
  sns_topic_namespace = "AWS/SNS"
  sns_topic_error_logs_metric_name = "NumberOfNotificationsFailed"
  queue_size_metric = "NumberOfMessagesSent"
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
  alarm_name                = "${var.component_name}-health-metric-failure"
  comparison_operator       = "LessThanThreshold"
  threshold                 = "1"
  evaluation_periods        = "3"
  metric_name               = "Health"
  namespace                 = local.nems_event_processor_metric_namespace
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
    namespace     = local.nems_event_processor_metric_namespace
    value         = 1
    default_value = 0
  }
}

resource "aws_cloudwatch_metric_alarm" "error_log_alarm" {
  alarm_name                = "${var.environment}-${var.component_name}-error-logs"
  comparison_operator       = "GreaterThanThreshold"
  threshold                 = "0"
  evaluation_periods        = "1"
  period                    = "60"
  metric_name               = local.error_logs_metric_name
  namespace                 = local.nems_event_processor_metric_namespace
  statistic                 = "Sum"
  alarm_description         = "This alarm monitors errors logs in ${var.component_name}"
  treat_missing_data        = "notBreaching"
  actions_enabled           = "true"
  alarm_actions             = [data.aws_sns_topic.alarm_notifications.arn]
  ok_actions                = [data.aws_sns_topic.alarm_notifications.arn]
}

data "aws_sns_topic" "alarm_notifications" {
  name = "${var.environment}-alarm-notifications-sns-topic"
}

resource "aws_cloudwatch_metric_alarm" "suspensions_sns_topic_error_log_alarm" {
  alarm_name                = "${local.suspensions_sns_topic_name}-error-logs"
  comparison_operator       = "GreaterThanThreshold"
  threshold                 = "0"
  evaluation_periods        = "1"
  period                    = "60"
  metric_name               = local.sns_topic_error_logs_metric_name
  namespace                 = local.sns_topic_namespace
  dimensions = {
    TopicName = local.suspensions_sns_topic_name
  }
  statistic                 = "Sum"
  alarm_description         = "This alarm monitors errors logs in ${local.suspensions_sns_topic_name}"
  treat_missing_data        = "notBreaching"
  actions_enabled           = "true"
  alarm_actions             = [data.aws_sns_topic.alarm_notifications.arn]
  ok_actions                = [data.aws_sns_topic.alarm_notifications.arn]
}

resource "aws_cloudwatch_metric_alarm" "unhandled_events_sns_topic_error_log_alarm" {
  alarm_name                = "${local.unhandled_events_sns_topic_name}-error-logs"
  comparison_operator       = "GreaterThanThreshold"
  threshold                 = "0"
  evaluation_periods        = "1"
  period                    = "60"
  metric_name               = local.sns_topic_error_logs_metric_name
  namespace                 = local.sns_topic_namespace
  dimensions = {
    TopicName = local.unhandled_events_sns_topic_name
  }
  statistic                 = "Sum"
  alarm_description         = "This alarm monitors errors logs in ${local.unhandled_events_sns_topic_name}"
  treat_missing_data        = "notBreaching"
  actions_enabled           = "true"
  alarm_actions             = [data.aws_sns_topic.alarm_notifications.arn]
  ok_actions                = [data.aws_sns_topic.alarm_notifications.arn]
}

resource "aws_cloudwatch_metric_alarm" "nems_incoming_dlq" {
  alarm_name                = "${var.environment}-${var.component_name}-dlq-size"
  comparison_operator       = "GreaterThanThreshold"
  threshold                 = "0"
  evaluation_periods        = "1"
  metric_name               = local.queue_size_metric
  namespace                 = local.sqs_namespace
  alarm_description         = "Alarm to alert messages landed dlq"
  statistic                 = "Maximum"
  period                    = "300"
  dimensions = {
    QueueName = aws_sqs_queue.dlq.name
  }
  alarm_actions             = [data.aws_sns_topic.alarm_notifications.arn]
  ok_actions                = [data.aws_sns_topic.alarm_notifications.arn]
}

resource "aws_cloudwatch_metric_alarm" "nems_incoming_queue_age_of_message" {
  alarm_name                = "${var.environment}-${var.component_name}-queue-age-of-message"
  comparison_operator       = "GreaterThanThreshold"
  threshold                 = "1800"
  evaluation_periods        = "1"
  metric_name               = "ApproximateAgeOfOldestMessage"
  namespace                 = local.sqs_namespace
  alarm_description         = "Alarm to alert approximate time for message in the queue"
  statistic                 = "Maximum"
  period                    = "300"
  dimensions = {
    QueueName = aws_sqs_queue.incoming_nems_events.name
  }
  alarm_actions             = [data.aws_sns_topic.alarm_notifications.arn]
  ok_actions                = [data.aws_sns_topic.alarm_notifications.arn]
}

resource "aws_cloudwatch_metric_alarm" "nems_incoming_audit" {
  alarm_name                = "${var.environment}-${var.component_name}-incoming-audit"
  comparison_operator       = "GreaterThanThreshold"
  threshold                 = "900"
  evaluation_periods        = "1"
  metric_name               = "ApproximateAgeOfOldestMessage"
  namespace                 = local.sqs_namespace
  alarm_description         = "Alarm for nems event processor incoming audit queue"
  statistic                 = "Maximum"
  period                    = "900"
  dimensions = {
    QueueName = aws_sqs_queue.nems_audit.name
  }
  alarm_actions             = [data.aws_sns_topic.alarm_notifications.arn]
  ok_actions                = [data.aws_sns_topic.alarm_notifications.arn]
}

resource "aws_cloudwatch_metric_alarm" "nems_dlq_audit" {
  alarm_name                = "${var.environment}-${var.component_name}-dlq-audit"
  comparison_operator       = "GreaterThanThreshold"
  threshold                 = "900"
  evaluation_periods        = "1"
  metric_name               = "ApproximateAgeOfOldestMessage"
  namespace                 = local.sqs_namespace
  alarm_description         = "Alarm for nems event processor dlq audit queue"
  statistic                 = "Maximum"
  period                    = "900"
  dimensions = {
    QueueName = aws_sqs_queue.nems_dlq_audit.name
  }
  alarm_actions             = [data.aws_sns_topic.alarm_notifications.arn]
  ok_actions                = [data.aws_sns_topic.alarm_notifications.arn]
}

resource "aws_cloudwatch_metric_alarm" "nems_unhandled_audit" {
  alarm_name                = "${var.environment}-${var.component_name}-unhandled-audit"
  comparison_operator       = "GreaterThanThreshold"
  threshold                 = "900"
  evaluation_periods        = "1"
  metric_name               = "ApproximateAgeOfOldestMessage"
  namespace                 = local.sqs_namespace
  alarm_description         = "Alarm for nems event processor unhandled audit queue"
  statistic                 = "Maximum"
  period                    = "900"
  dimensions = {
    QueueName = aws_sqs_queue.unhandled_audit.name
  }
  alarm_actions             = [data.aws_sns_topic.alarm_notifications.arn]
  ok_actions                = [data.aws_sns_topic.alarm_notifications.arn]
}

resource "aws_cloudwatch_metric_alarm" "nems_incoming_receiving_in_working_hours" {
  alarm_name                = "${var.environment}-nems-incoming-receiving-in-working-hours"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = "240" # 4 hours (given period is set to 1 min/60sec)
  threshold                 = "0"
  alarm_description         = "Alarm for when nems incoming messages are not coming over working hour. In the graph 1 means alarm, 0 means no alarm"
  actions_enabled           = true
  alarm_actions             = [data.aws_sns_topic.alarm_notifications.arn]
  ok_actions                = [data.aws_sns_topic.alarm_notifications.arn]
  metric_query {
    id = "msgCount"

    metric {
      metric_name = "NumberOfMessagesReceived"
      namespace   = local.sqs_namespace
      period      = "60"
      stat        = "Sum"
      unit        = "Count"

      dimensions = {
        QueueName = aws_sqs_queue.incoming_nems_events.name
      }
    }
  }

  metric_query {
    id          = "isWorkingHour"
    expression  = "IF(HOUR(msgCount) >= 7 && HOUR(msgCount) <= 19 && DAY(msgCount) < 6, 1, 0)"
  }
  metric_query {
    id          = "e1"
    expression  = "IF(msgCount == 0 && isWorkingHour == 1, 1, 0)"
    label       = "IncomingMessageInWorkingHours"
    return_data = "true"
  }
}
