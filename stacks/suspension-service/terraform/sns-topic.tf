resource "aws_sns_topic" "mof_updated" {
  name                          = "${var.environment}-${var.component_name}-mof-updated-sns-topic"
  kms_master_key_id             = aws_kms_key.mof_updated.id
  sqs_failure_feedback_role_arn = aws_iam_role.sns_failure_feedback_role.arn

  tags = {
    Name        = "${var.environment}-${var.component_name}-mof-updated-sns-topic"
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}

resource "aws_sns_topic" "mof_not_updated" {
  name                          = "${var.environment}-${var.component_name}-mof-not-updated-sns-topic"
  kms_master_key_id             = aws_kms_key.mof_not_updated.id
  sqs_failure_feedback_role_arn = aws_iam_role.sns_failure_feedback_role.arn

  tags = {
    Name        = "${var.environment}-${var.component_name}-mof-updated-sns-topic"
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}

resource "aws_sns_topic" "not_suspended" {
  name                          = "${var.environment}-${var.component_name}-not-suspended-sns-topic"
  kms_master_key_id             = aws_kms_key.not_suspended.id
  sqs_failure_feedback_role_arn = aws_iam_role.sns_failure_feedback_role.arn

  tags = {
    Name        = "${var.environment}-${var.component_name}-not-suspended-sns-topic"
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}

resource "aws_sns_topic" "invalid_suspension" {
  name                          = "${var.environment}-${var.component_name}-invalid-suspension-sns-topic"
  kms_master_key_id             = aws_kms_key.invalid_suspension.id
  sqs_failure_feedback_role_arn = aws_iam_role.sns_failure_feedback_role.arn

  tags = {
    Name        = "${var.environment}-${var.component_name}-invalid-suspension-sns-topic"
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}

resource "aws_sns_topic" "invalid_suspension_audit_topic" {
  name                          = "${var.environment}-${var.component_name}-invalid-suspension-audit-sns-topic"
  kms_master_key_id             = aws_kms_key.invalid_suspension_audit.id
  sqs_failure_feedback_role_arn = aws_iam_role.sns_failure_feedback_role.arn

  tags = {
    Name        = "${var.environment}-${var.component_name}-invalid-suspension-audit-sns-topic"
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}

resource "aws_sns_topic" "event_out_of_order" {
  name                          = "${var.environment}-${var.component_name}-event-out-of-order"
  kms_master_key_id             = aws_kms_key.event_out_of_order.id
  sqs_failure_feedback_role_arn = aws_iam_role.sns_failure_feedback_role.arn

  tags = {
    Name        = "${var.environment}-${var.component_name}-event-out-of-order-sns-topic"
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}

resource "aws_sns_topic" "deceased_patient" {
  name                          = "${var.environment}-${var.component_name}-deceased-patient"
  kms_master_key_id             = aws_kms_key.deceased_patient.id
  sqs_failure_feedback_role_arn = aws_iam_role.sns_failure_feedback_role.arn

  tags = {
    Name        = "${var.environment}-${var.component_name}-deceased-patient-sns-topic"
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}

resource "aws_sns_topic" "active_suspensions" {
  name                          = "${var.environment}-${var.component_name}-active-suspensions-sns-topic"
  kms_master_key_id             = aws_kms_key.active_suspensions.id
  sqs_failure_feedback_role_arn = aws_iam_role.sns_failure_feedback_role.arn

  tags = {
    Name        = "${var.environment}-${var.component_name}-active-suspensions-sns-topic"
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}

data "aws_sns_topic" "alarm_notifications" {
  name = "${var.environment}-alarm-notifications-sns-topic"
}

resource "aws_sns_topic_policy" "deny_http" {
  for_each = toset(local.sns_arns)

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