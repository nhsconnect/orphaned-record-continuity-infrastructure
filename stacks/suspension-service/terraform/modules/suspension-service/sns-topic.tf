resource "aws_sns_topic" "repo_incoming" {
  name                          = "${var.environment}-${var.component_name}-repo-incoming"
  kms_master_key_id             = aws_kms_key.repo_incoming.id
  sqs_failure_feedback_role_arn = var.sns_sqs_role_arn

  tags = {
    Name        = "${var.environment}-${var.component_name}-repo-incoming-sns-topic"
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
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
