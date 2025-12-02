resource "aws_sns_topic_subscription" "re_registration_audit" {
  protocol             = "sqs"
  raw_message_delivery = true
  topic_arn            = aws_sns_topic.re_registration_audit_topic.arn
  endpoint             = aws_sqs_queue.re_registration_audit_uploader.arn
}

resource "aws_sns_topic_subscription" "suspension_active_suspensions" {
  protocol             = "sqs"
  raw_message_delivery = true
  topic_arn            = data.aws_ssm_parameter.suspension_active_suspensions_topic_arn.value
  endpoint             = aws_sqs_queue.active_suspensions.arn
}

resource "aws_sns_topic_subscription" "end_of_transfer_active_suspensions" {
  protocol             = "sqs"
  raw_message_delivery = true
  topic_arn            = data.aws_ssm_parameter.end_of_transfer_active_suspensions_topic_arn.value
  endpoint             = aws_sqs_queue.active_suspensions.arn
}