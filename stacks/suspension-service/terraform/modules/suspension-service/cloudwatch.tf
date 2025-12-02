locals {
  sqs_namespace                       = "AWS/SQS"
}

resource "aws_cloudwatch_metric_alarm" "suspensions_queue_age_of_message" {
  alarm_name          = "${var.environment}-${var.component_name}-queue-age-of-message"
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.threshold_for_suspensions_queue_age_of_message
  evaluation_periods  = "1"
  metric_name         = "ApproximateAgeOfOldestMessage"
  namespace           = local.sqs_namespace
  alarm_description   = "Alarm to alert approximate time for message in the queue"
  statistic           = "Maximum"
  period              = var.period_of_age_of_message_metric
  dimensions = {
    QueueName = aws_sqs_queue.suspensions.name
  }
  alarm_actions = [data.aws_sns_topic.alarm_notifications.arn]
  ok_actions    = [data.aws_sns_topic.alarm_notifications.arn]
}

data "aws_sns_topic" "alarm_notifications" {
  name = "${var.environment}-alarm-notifications-sns-topic"
}
