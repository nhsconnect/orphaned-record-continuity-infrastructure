resource "aws_cloudwatch_metric_alarm" "ehr_out_service_incoming_age_of_message" {
  alarm_name          = "${var.environment}-${var.component_name}-incoming-queue-approx-age-of-oldest-message"
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.threshold_approx_age_oldest_message
  evaluation_periods  = "1"
  metric_name         = "ApproximateAgeOfOldestMessage"
  namespace           = "AWS/SQS"
  alarm_description   = "Alarm to alert approximate time for message in the queue"
  statistic           = "Maximum"
  period              = var.period_of_age_of_message_metric
  dimensions = {
    QueueName = aws_sqs_queue.service_incoming.name
  }
  alarm_actions = [data.aws_sns_topic.alarm_notifications.arn]
  ok_actions    = [data.aws_sns_topic.alarm_notifications.arn]
}