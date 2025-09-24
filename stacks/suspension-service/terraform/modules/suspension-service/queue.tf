locals {
  suspensions_queue_name                 = "${var.environment}-${var.component_name}-suspensions"
  repo_incoming_observability_queue_name = "${var.environment}-${var.component_name}-repo-incoming-observability"
}
resource "aws_sqs_queue" "repo_incoming_observability_queue" {
  name                      = local.repo_incoming_observability_queue_name
  message_retention_seconds = 1209600
  kms_master_key_id         = aws_kms_key.repo_incoming.id

  tags = {
    Name        = local.repo_incoming_observability_queue_name
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}

resource "aws_sns_topic_subscription" "repo_incoming_observability_queue" {
  protocol             = "sqs"
  raw_message_delivery = true
  topic_arn            = aws_sns_topic.repo_incoming.arn
  endpoint             = aws_sqs_queue.repo_incoming_observability_queue.arn
}

resource "aws_sqs_queue" "suspensions" {
  name                       = local.suspensions_queue_name
  message_retention_seconds  = 1209600
  kms_master_key_id          = data.aws_ssm_parameter.suspensions_kms_key_id.value
  receive_wait_time_seconds  = 20
  visibility_timeout_seconds = 240

  tags = {
    Name        = local.suspensions_queue_name
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}

resource "aws_sns_topic_subscription" "suspensions_topic" {
  protocol             = "sqs"
  raw_message_delivery = true
  topic_arn            = data.aws_ssm_parameter.suspensions_sns_topic_arn.value
  endpoint             = aws_sqs_queue.suspensions.arn
}

resource "aws_iam_policy" "suspensions_queue_send_message_policy" {
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      "Sid"    = "shsqsstatement",
      "Effect" = "Allow",
      "Action" = [
        "sqs:SendMessage",
      ],
      "Resource" = [
        aws_sqs_queue.suspensions.arn
      ]
      },
      {
        "Effect" = "Allow",
        "Action" = [
          "kms:GenerateDataKey",
          "kms:Decrypt"
        ],
        "Resource" = [
          "*"
        ]
  }] })
}
