locals {
  sns_topic_arns = [
    aws_sns_topic.alarm_notifications.arn
  ]
}

resource "aws_sns_topic" "alarm_notifications" {
  name              = "${var.environment}-alarm-notifications-sns-topic"
  kms_master_key_id = aws_kms_key.alarm_notification.id

  tags = {
    Name        = "${var.environment}-alarm-notifications-sns-topic"
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}

resource "aws_sns_topic_policy" "deny_http" {
  for_each = toset(local.sns_topic_arns)

  arn = each.value

  policy = <<EOF
{
  "Version": "2008-10-17",
  "Id": "__default_policy_ID",
  "Statement": [
    {
      "Sid": "__default_statement_ID",
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": [
        "SNS:GetTopicAttributes",
        "SNS:SetTopicAttributes",
        "SNS:AddPermission",
        "SNS:RemovePermission",
        "SNS:DeleteTopic",
        "SNS:Subscribe",
        "SNS:ListSubscriptionsByTopic",
        "SNS:Publish",
        "SNS:Receive"
      ],
      "Resource": "${each.value}",
      "Condition": {
        "StringEquals": {
          "AWS:SourceOwner": "${data.aws_caller_identity.current.account_id}"
        }
      }
    },
    {
      "Sid": "DenyHTTPSubscription",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "sns:Subscribe",
      "Resource": "${each.value}",
      "Condition": {
        "StringEquals": {
          "sns:Protocol": "http"
        }
      }
    },
    {
      "Sid": "DenyHTTPPublish",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "SNS:Publish",
      "Resource": "${each.value}",
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
EOF
}

resource "aws_kms_key" "alarm_notification" {
  description         = "Custom KMS Key to enable server side encryption for alarm notifications"
  policy              = data.aws_iam_policy_document.alarm_notification_kms_key_policy_doc.json
  enable_key_rotation = true

  tags = {
    Name        = "${var.environment}-alarm_notification-kms-key"
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}

resource "aws_kms_alias" "alarm_notification_encryption" {
  name          = "alias/alarm-notification-encryption-kms-key"
  target_key_id = aws_kms_key.alarm_notification.id
}

data "aws_iam_policy_document" "alarm_notification_kms_key_policy_doc" {
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