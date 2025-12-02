locals {
  hl7-message-sent-observability-queue-name = "${var.environment}-hl7-message-sent-observability"
}

resource "aws_sqs_queue" "hl7_message_sent_observability" {
  name                       = local.hl7-message-sent-observability-queue-name
  message_retention_seconds  = 86400
  kms_master_key_id          = aws_kms_key.hl7_message_sent_observability.key_id
  receive_wait_time_seconds  = 20
  visibility_timeout_seconds = 900

  tags = {
    Name        = local.hl7-message-sent-observability-queue-name
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}

resource "aws_kms_key" "hl7_message_sent_observability" {
  description         = "Custom KMS Key to enable server side encryption for SQS"
  policy              = data.aws_iam_policy_document.kms_key_policy_doc.json
  enable_key_rotation = true

  tags = {
    Name        = "${local.hl7-message-sent-observability-queue-name}-kms-key"
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}

resource "aws_kms_alias" "hl7_message_sent_observability_encryption" {
  name          = "alias/hl7-message-sent-observability-encryption-kms-key"
  target_key_id = aws_kms_key.hl7_message_sent_observability.id
}

data "aws_iam_policy_document" "kms_key_policy_doc" {
  statement {
    effect = "Allow"

    principals {
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
      type        = "AWS"
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    effect = "Allow"

    principals {
      identifiers = ["sns.amazonaws.com"]
      type        = "Service"
    }

    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey*"
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    principals {
      identifiers = ["cloudwatch.amazonaws.com"]
      type        = "Service"
    }

    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey*"
    ]

    resources = ["*"]
  }
}
