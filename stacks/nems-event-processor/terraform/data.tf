data "aws_caller_identity" "current" {}

data "aws_ssm_parameter" "private_zone_id" {
  name = "/repo/${var.environment}/output/prm-deductions-infra/private-root-zone-id"
}

data "aws_ssm_parameter" "deductions_private_private_subnets" {
  name = "/repo/${var.environment}/output/prm-deductions-infra/deductions-private-private-subnets"
}

data "aws_ssm_parameter" "deductions_private_vpc_id" {
  name = "/repo/${var.environment}/output/prm-deductions-infra/private-vpc-id"
}

data "aws_ssm_parameter" "deductions_private_db_subnets" {
  name = "/repo/${var.environment}/output/prm-deductions-infra/deductions-private-database-subnets"
}

data "aws_ssm_parameter" "sns_sqs_kms_key_id" {
  name = "/repo/${var.environment}/output/prm-deductions-mesh-forwarder/sns-sqs-kms-key-id"
}

data "aws_ssm_parameter" "nems_events_topic_arn" {
  name = "/repo/${var.environment}/output/prm-deductions-mesh-forwarder/nems-events-topic-arn"
}

data "aws_ssm_parameter" "dynamodb_name" {
  name = "/repo/${var.environment}/output/prm-deductions-infra/ehr-transfer-tracker-db-name"
}

data "aws_iam_policy_document" "sqs_nems_event_policy_doc" {
  statement {

    effect = "Allow"

    actions = [
      "sqs:SendMessage"
    ]

    principals {
      identifiers = ["sns.amazonaws.com"]
      type        = "Service"
    }

    resources = [
      aws_sqs_queue.incoming_nems_events.arn
    ]

    condition {
      test     = "ArnEquals"
      values   = [data.aws_ssm_parameter.nems_events_topic_arn.value]
      variable = "aws:SourceArn"
    }
  }
}

data "aws_iam_policy_document" "unhandled_events_sns_topic_access_to_queue" {
  statement {

    effect = "Allow"

    actions = [
      "sqs:SendMessage"
    ]

    principals {
      identifiers = ["sns.amazonaws.com"]
      type        = "Service"
    }

    resources = [
      aws_sqs_queue.unhandled_events.arn, aws_sqs_queue.unhandled_audit.arn
    ]

    condition {
      test     = "ArnEquals"
      values   = [aws_sns_topic.unhandled_events.arn]
      variable = "aws:SourceArn"
    }
  }
}

data "aws_iam_policy_document" "suspensions_sns_topic_access_to_queue" {
  statement {
    effect = "Allow"

    actions = [
      "sqs:SendMessage"
    ]

    principals {
      identifiers = ["sns.amazonaws.com"]
      type        = "Service"
    }

    resources = [
      aws_sqs_queue.suspensions_observability.arn
    ]

    condition {
      test     = "ArnEquals"
      values   = [aws_sns_topic.suspensions.arn]
      variable = "aws:SourceArn"
    }
  }
}

data "aws_iam_policy_document" "sns_service_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = [
        "sns.amazonaws.com"
      ]
    }
  }
}

data "aws_iam_policy_document" "sns_failure_feedback_policy" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:PutMetricFilter",
      "logs:PutRetentionPolicy"
    ]
    resources = [
      "*"
    ]
  }
}

data "aws_iam_policy_document" "dlq_sns_topic_access_to_queue" {
  statement {
    effect = "Allow"

    actions = [
      "sqs:SendMessage"
    ]

    principals {
      identifiers = ["sns.amazonaws.com"]
      type        = "Service"
    }

    resources = [
      aws_sqs_queue.dlq.arn, aws_sqs_queue.nems_dlq_audit.arn
    ]

    condition {
      test     = "ArnEquals"
      values   = [aws_sns_topic.dlq.arn]
      variable = "aws:SourceArn"
    }
  }
}

data "aws_iam_policy_document" "nems_audit_sns_topic_access_to_queue" {
  statement {
    effect = "Allow"

    actions = [
      "sqs:SendMessage"
    ]

    principals {
      identifiers = ["sns.amazonaws.com"]
      type        = "Service"
    }

    resources = [
      aws_sqs_queue.nems_audit.arn
    ]

    condition {
      test     = "ArnEquals"
      values   = [aws_sns_topic.nems_audit.arn]
      variable = "aws:SourceArn"
    }
  }
}

data "aws_iam_policy_document" "re_registration_sns_topic_access_to_queue" {
  statement {
    effect = "Allow"

    actions = [
      "sqs:SendMessage"
    ]

    principals {
      identifiers = ["sns.amazonaws.com"]
      type        = "Service"
    }

    resources = [
      aws_sqs_queue.re_registration_observability.arn
    ]

    condition {
      test     = "ArnEquals"
      values   = [aws_sns_topic.re_registrations_topic.arn]
      variable = "aws:SourceArn"
    }
  }
}

data "aws_iam_policy_document" "sns_cross_account_permissions_policy_doc" {
  statement {
    effect = "Allow"

    actions = [
      "sns:Subscribe"
    ]

    principals {
      identifiers = var.re_registration_sns_topic_cross_account_subscriber_account_ids
      type        = "AWS"
    }

    resources = [aws_sns_topic.re_registrations_topic.arn]
  }
}