resource "aws_cloudwatch_metric_alarm" "repo_incoming_age_of_message" {
  alarm_name          = "${var.environment}-${var.component_name}-repo-incoming-approx-age-of-oldest-message"
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.threshold_approx_age_oldest_message
  evaluation_periods  = "1"
  metric_name         = "ApproximateAgeOfOldestMessage"
  namespace           = local.sqs_namespace
  alarm_description   = "Alarm to alert approximate time for message in the queue"
  statistic           = "Maximum"
  period              = var.period_of_age_of_message_metric
  dimensions = {
    QueueName = aws_sqs_queue.repo_incoming.name
  }
  alarm_actions = [data.aws_sns_topic.alarm_notifications.arn]
  ok_actions    = [data.aws_sns_topic.alarm_notifications.arn]
}

resource "aws_cloudwatch_metric_alarm" "ehr_complete_age_of_message" {
  alarm_name          = "${var.environment}-${var.component_name}-ehr-complete-approx-age-of-oldest-message"
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.threshold_approx_age_oldest_message
  evaluation_periods  = "1"
  metric_name         = "ApproximateAgeOfOldestMessage"
  namespace           = local.sqs_namespace
  alarm_description   = "Alarm to alert approximate time for message in the queue"
  statistic           = "Maximum"
  period              = var.period_of_age_of_message_metric
  dimensions = {
    QueueName = aws_sqs_queue.ehr_complete.name
  }
  alarm_actions = [data.aws_sns_topic.alarm_notifications.arn]
  ok_actions    = [data.aws_sns_topic.alarm_notifications.arn]
}

resource "aws_cloudwatch_metric_alarm" "large_ehr_age_of_message" {
  alarm_name          = "${var.environment}-${var.component_name}-large-ehr-approx-age-of-oldest-message"
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.threshold_approx_age_oldest_message
  evaluation_periods  = "1"
  metric_name         = "ApproximateAgeOfOldestMessage"
  namespace           = local.sqs_namespace
  alarm_description   = "Alarm to alert approximate time for message in the queue"
  statistic           = "Maximum"
  period              = var.period_of_age_of_message_metric
  dimensions = {
    QueueName = aws_sqs_queue.large_ehr.name
  }
  alarm_actions = [data.aws_sns_topic.alarm_notifications.arn]
  ok_actions    = [data.aws_sns_topic.alarm_notifications.arn]
}


resource "aws_cloudwatch_metric_alarm" "small_ehr_age_of_message" {
  alarm_name          = "${var.environment}-${var.component_name}-small-ehr-approx-age-of-oldest-message"
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.threshold_approx_age_oldest_message
  evaluation_periods  = "1"
  metric_name         = "ApproximateAgeOfOldestMessage"
  namespace           = local.sqs_namespace
  alarm_description   = "Alarm to alert approximate time for message in the queue"
  statistic           = "Maximum"
  period              = var.period_of_age_of_message_metric
  dimensions = {
    QueueName = aws_sqs_queue.small_ehr.name
  }
  alarm_actions = [data.aws_sns_topic.alarm_notifications.arn]
  ok_actions    = [data.aws_sns_topic.alarm_notifications.arn]
}

resource "aws_cloudwatch_metric_alarm" "large_message_fragments_age_of_message" {
  alarm_name          = "${var.environment}-${var.component_name}-large-message-fragments-approx-age-of-oldest-message"
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.threshold_approx_age_oldest_message
  evaluation_periods  = "1"
  metric_name         = "ApproximateAgeOfOldestMessage"
  namespace           = local.sqs_namespace
  alarm_description   = "Alarm to alert approximate time for message in the queue"
  statistic           = "Maximum"
  period              = var.period_of_age_of_message_metric
  dimensions = {
    QueueName = aws_sqs_queue.large_message_fragments.name
  }
  alarm_actions = [data.aws_sns_topic.alarm_notifications.arn]
  ok_actions    = [data.aws_sns_topic.alarm_notifications.arn]
}

resource "aws_cloudwatch_metric_alarm" "negative_acks_size" {
  alarm_name          = "${var.environment}-${var.component_name}-negative-acks-size"
  comparison_operator = "GreaterThanThreshold"
  threshold           = "0"
  evaluation_periods  = "1"
  metric_name         = "NumberOfMessagesSent"
  namespace           = local.sqs_namespace
  alarm_description   = "Alarm to alert messages landed dlq"
  statistic           = "Maximum"
  period              = "300"
  dimensions = {
    QueueName = aws_sqs_queue.negative_acks.name
  }
  alarm_actions = [data.aws_sns_topic.alarm_notifications.arn]
  ok_actions    = [data.aws_sns_topic.alarm_notifications.arn]
}

resource "aws_cloudwatch_metric_alarm" "parsing_dlq_size" {
  alarm_name          = "${var.environment}-${var.component_name}-parsing-dlq-size"
  comparison_operator = "GreaterThanThreshold"
  threshold           = "0"
  evaluation_periods  = "1"
  metric_name         = "NumberOfMessagesSent"
  namespace           = local.sqs_namespace
  alarm_description   = "Alarm to alert messages landed dlq"
  statistic           = "Maximum"
  period              = "300"
  dimensions = {
    QueueName = aws_sqs_queue.parsing_dlq.name
  }
  alarm_actions = [data.aws_sns_topic.alarm_notifications.arn]
  ok_actions    = [data.aws_sns_topic.alarm_notifications.arn]
}

resource "aws_cloudwatch_metric_alarm" "error_log_alarm" {
  alarm_name          = "${var.environment}-${var.component_name}-error-logs"
  comparison_operator = "GreaterThanThreshold"
  threshold           = "0"
  evaluation_periods  = "1"
  period              = "60"
  metric_name         = local.error_logs_metric_name
  namespace           = local.ehr_transfer_service_metric_namespace
  statistic           = "Sum"
  alarm_description   = "This alarm monitors errors logs in ${var.component_name}"
  treat_missing_data  = "notBreaching"
  actions_enabled     = "true"
  alarm_actions       = [data.aws_sns_topic.alarm_notifications.arn]
  ok_actions          = [data.aws_sns_topic.alarm_notifications.arn]
}

resource "aws_cloudwatch_metric_alarm" "health_metric_failure_alarm" {
  alarm_name          = "${var.component_name}-health-metric-failure"
  comparison_operator = "LessThanThreshold"
  threshold           = "1"
  evaluation_periods  = "1"
  metric_name         = "Health"
  namespace           = local.ehr_transfer_service_metric_namespace
  alarm_description   = "Alarm to flag failed health checks"
  statistic           = "Maximum"
  treat_missing_data  = "breaching"
  period              = "60"
  dimensions = {
    "Environment" = var.environment
  }
  alarm_actions = [data.aws_sns_topic.alarm_notifications.arn]
  ok_actions    = [data.aws_sns_topic.alarm_notifications.arn]
}

resource "aws_cloudwatch_metric_alarm" "ehr_complete_sns_topic_error_log_alarm" {
  alarm_name          = "${aws_sns_topic.ehr_complete.name}-error-logs"
  comparison_operator = "GreaterThanThreshold"
  threshold           = "0"
  evaluation_periods  = "1"
  period              = "60"
  metric_name         = local.sns_topic_error_logs_metric_name
  namespace           = local.sns_topic_namespace
  dimensions = {
    TopicName = aws_sns_topic.ehr_complete.name
  }
  statistic          = "Sum"
  alarm_description  = "This alarm monitors errors logs in ${aws_sns_topic.ehr_complete.name}"
  treat_missing_data = "notBreaching"
  actions_enabled    = "true"
  alarm_actions      = [data.aws_sns_topic.alarm_notifications.arn]
  ok_actions         = [data.aws_sns_topic.alarm_notifications.arn]
}

resource "aws_cloudwatch_metric_alarm" "large_ehr_sns_topic_error_log_alarm" {
  alarm_name          = "${aws_sns_topic.large_ehr.name}-error-logs"
  comparison_operator = "GreaterThanThreshold"
  threshold           = "0"
  evaluation_periods  = "1"
  period              = "60"
  metric_name         = local.sns_topic_error_logs_metric_name
  namespace           = local.sns_topic_namespace
  dimensions = {
    TopicName = aws_sns_topic.large_ehr.name
  }
  statistic          = "Sum"
  alarm_description  = "This alarm monitors errors logs in ${aws_sns_topic.large_ehr.name}"
  treat_missing_data = "notBreaching"
  actions_enabled    = "true"
  alarm_actions      = [data.aws_sns_topic.alarm_notifications.arn]
  ok_actions         = [data.aws_sns_topic.alarm_notifications.arn]
}

resource "aws_cloudwatch_metric_alarm" "small_ehr_sns_topic_error_log_alarm" {
  alarm_name          = "${aws_sns_topic.small_ehr.name}-error-logs"
  comparison_operator = "GreaterThanThreshold"
  threshold           = "0"
  evaluation_periods  = "1"
  period              = "60"
  metric_name         = local.sns_topic_error_logs_metric_name
  namespace           = local.sns_topic_namespace
  dimensions = {
    TopicName = aws_sns_topic.small_ehr.name
  }
  statistic          = "Sum"
  alarm_description  = "This alarm monitors errors logs in ${aws_sns_topic.small_ehr.name}"
  treat_missing_data = "notBreaching"
  actions_enabled    = "true"
  alarm_actions      = [data.aws_sns_topic.alarm_notifications.arn]
  ok_actions         = [data.aws_sns_topic.alarm_notifications.arn]
}

resource "aws_cloudwatch_metric_alarm" "large_message_fragments_sns_topic_error_log_alarm" {
  alarm_name          = "${aws_sns_topic.large_message_fragments.name}-error-logs"
  comparison_operator = "GreaterThanThreshold"
  threshold           = "0"
  evaluation_periods  = "1"
  period              = "60"
  metric_name         = local.sns_topic_error_logs_metric_name
  namespace           = local.sns_topic_namespace
  dimensions = {
    TopicName = aws_sns_topic.large_message_fragments.name
  }
  statistic          = "Sum"
  alarm_description  = "This alarm monitors errors logs in ${aws_sns_topic.large_message_fragments.name}"
  treat_missing_data = "notBreaching"
  actions_enabled    = "true"
  alarm_actions      = [data.aws_sns_topic.alarm_notifications.arn]
  ok_actions         = [data.aws_sns_topic.alarm_notifications.arn]
}

resource "aws_cloudwatch_metric_alarm" "negative_acks_sns_topic_error_log_alarm" {
  alarm_name          = "${aws_sns_topic.negative_acks.name}-error-logs"
  comparison_operator = "GreaterThanThreshold"
  threshold           = "0"
  evaluation_periods  = "1"
  period              = "60"
  metric_name         = local.sns_topic_error_logs_metric_name
  namespace           = local.sns_topic_namespace
  dimensions = {
    TopicName = aws_sns_topic.negative_acks.name
  }
  statistic          = "Sum"
  alarm_description  = "This alarm monitors errors logs in ${aws_sns_topic.negative_acks.name}"
  treat_missing_data = "notBreaching"
  actions_enabled    = "true"
  alarm_actions      = [data.aws_sns_topic.alarm_notifications.arn]
  ok_actions         = [data.aws_sns_topic.alarm_notifications.arn]
}

resource "aws_cloudwatch_metric_alarm" "positive_acks_sns_topic_error_log_alarm" {
  alarm_name          = "${aws_sns_topic.positive_acks.name}-error-logs"
  comparison_operator = "GreaterThanThreshold"
  threshold           = "0"
  evaluation_periods  = "1"
  period              = "60"
  metric_name         = local.sns_topic_error_logs_metric_name
  namespace           = local.sns_topic_namespace
  dimensions = {
    TopicName = aws_sns_topic.positive_acks.name
  }
  statistic          = "Sum"
  alarm_description  = "This alarm monitors errors logs in ${aws_sns_topic.positive_acks.name}"
  treat_missing_data = "notBreaching"
  actions_enabled    = "true"
  alarm_actions      = [data.aws_sns_topic.alarm_notifications.arn]
  ok_actions         = [data.aws_sns_topic.alarm_notifications.arn]
}

resource "aws_cloudwatch_metric_alarm" "parsing_dlq_sns_topic_error_log_alarm" {
  alarm_name          = "${aws_sns_topic.parsing_dlq.name}-error-logs"
  comparison_operator = "GreaterThanThreshold"
  threshold           = "0"
  evaluation_periods  = "1"
  period              = "60"
  metric_name         = local.sns_topic_error_logs_metric_name
  namespace           = local.sns_topic_namespace
  dimensions = {
    TopicName = aws_sns_topic.parsing_dlq.name
  }
  statistic          = "Sum"
  alarm_description  = "This alarm monitors errors logs in ${aws_sns_topic.parsing_dlq.name}"
  treat_missing_data = "notBreaching"
  actions_enabled    = "true"
  alarm_actions      = [data.aws_sns_topic.alarm_notifications.arn]
  ok_actions         = [data.aws_sns_topic.alarm_notifications.arn]
}

resource "aws_cloudwatch_metric_alarm" "transfer_complete_sns_topic_error_log_alarm" {
  alarm_name          = "${aws_sns_topic.transfer_complete.name}-error-logs"
  comparison_operator = "GreaterThanThreshold"
  threshold           = "0"
  evaluation_periods  = "1"
  period              = "60"
  metric_name         = local.sns_topic_error_logs_metric_name
  namespace           = local.sns_topic_namespace
  dimensions = {
    TopicName = aws_sns_topic.transfer_complete.name
  }
  statistic          = "Sum"
  alarm_description  = "This alarm monitors errors logs in ${aws_sns_topic.transfer_complete.name}"
  treat_missing_data = "notBreaching"
  actions_enabled    = "true"
  alarm_actions      = [data.aws_sns_topic.alarm_notifications.arn]
  ok_actions         = [data.aws_sns_topic.alarm_notifications.arn]
}

resource "aws_cloudwatch_metric_alarm" "ehr_in_unhandled_sns_topic_error_log_alarm" {
  alarm_name          = "${aws_sns_topic.ehr_in_unhandled.name}-error-logs"
  comparison_operator = "GreaterThanThreshold"
  threshold           = "0"
  evaluation_periods  = "1"
  period              = "60"
  metric_name         = local.sns_topic_error_logs_metric_name
  namespace           = local.sns_topic_namespace
  dimensions = {
    TopicName = aws_sns_topic.ehr_in_unhandled.name
  }
  statistic          = "Sum"
  alarm_description  = "This alarm monitors errors logs in ${aws_sns_topic.ehr_in_unhandled.name}"
  treat_missing_data = "notBreaching"
  actions_enabled    = "true"
  alarm_actions      = [data.aws_sns_topic.alarm_notifications.arn]
  ok_actions         = [data.aws_sns_topic.alarm_notifications.arn]
}

resource "aws_cloudwatch_metric_alarm" "splunk_uploader_sns_topic_error_log_alarm" {
  alarm_name          = "${aws_sns_topic.splunk_uploader.name}-error-logs"
  comparison_operator = "GreaterThanThreshold"
  threshold           = "0"
  evaluation_periods  = "1"
  period              = "60"
  metric_name         = local.sns_topic_error_logs_metric_name
  namespace           = local.sns_topic_namespace
  dimensions = {
    TopicName = aws_sns_topic.splunk_uploader.name
  }
  statistic          = "Sum"
  alarm_description  = "This alarm monitors errors logs in ${aws_sns_topic.splunk_uploader.name}"
  treat_missing_data = "notBreaching"
  actions_enabled    = "true"
  alarm_actions      = [data.aws_sns_topic.alarm_notifications.arn]
  ok_actions         = [data.aws_sns_topic.alarm_notifications.arn]
}
