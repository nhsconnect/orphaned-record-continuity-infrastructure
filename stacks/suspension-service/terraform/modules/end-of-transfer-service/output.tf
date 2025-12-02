output "end_of_transfer_sns_topic" {
  value = data.aws_ssm_parameter.transfer_complete_topic_arn.value
}

output "transfer_complete_queue_name" {
  value = aws_sqs_queue.transfer_complete.name
}

output "transfer_complete_queue_arn" {
  value = aws_sqs_queue.transfer_complete.arn
}