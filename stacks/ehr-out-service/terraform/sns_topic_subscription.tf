resource "aws_sns_topic_subscription" "ehr_in_unhandled_topic" {
  protocol             = "sqs"
  raw_message_delivery = true
  topic_arn            = data.aws_ssm_parameter.ehr_in_unhandled_sns_topic_arn.value
  endpoint             = aws_sqs_queue.service_incoming.arn
}