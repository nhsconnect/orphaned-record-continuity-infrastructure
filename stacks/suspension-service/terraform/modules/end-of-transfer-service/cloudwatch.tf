locals {
  sqs_namespace = "AWS/SQS"
}

resource "aws_cloudwatch_metric_alarm" "transfer_complete_queue_age_of_message" {
  alarm_name          = "${var.environment}-${var.component_name}-transfer-complete-approx-age-of-oldest-message"
  comparison_operator = "GreaterThanThreshold"
  threshold           = "1800"
  evaluation_periods  = "1"
  metric_name         = "ApproximateAgeOfOldestMessage"
  namespace           = local.sqs_namespace
  alarm_description   = "This alarm triggers when messages on the transfer complete queue is not polled by end of transfer service in last 30 mins"
  statistic           = "Maximum"
  period              = "300"
  dimensions = {
    QueueName = aws_sqs_queue.transfer_complete.name
  }
  alarm_actions = [data.aws_sns_topic.alarm_notifications.arn]
  ok_actions    = [data.aws_sns_topic.alarm_notifications.arn]
}

data "aws_sns_topic" "alarm_notifications" {
  name = "${var.environment}-alarm-notifications-sns-topic"
}