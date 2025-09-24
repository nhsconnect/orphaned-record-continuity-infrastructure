resource "aws_kms_key" "suspensions" {
  description = "Custom KMS Key to enable server side encryption for Suspensions Events"
  policy      = data.aws_iam_policy_document.kms_key_policy_doc.json
  enable_key_rotation = true

  tags = {
    Name        = "${var.environment}-sns-sqs-kms-key"
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}

resource "aws_kms_alias" "suspensions_encryption" {
  name          = "alias/suspensions-kms-key"
  target_key_id = aws_kms_key.suspensions.id
}

resource "aws_ssm_parameter" "suspensions_kms_key_id" {
  name  = "/repo/${var.environment}/output/${var.repo_name}/suspensions-kms-key-id"
  type  = "String"
  value = aws_kms_key.suspensions.id

  tags = {
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}

# Dead Letter Queue
resource "aws_kms_key" "dlq" {
  description = "Custom KMS Key to enable server side encryption for dlq"
  policy      = data.aws_iam_policy_document.kms_key_policy_doc.json
  enable_key_rotation = true

  tags = {
    Name        = "${var.environment}-dlq-kms-key"
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}

resource "aws_kms_alias" "dlq_encryption" {
  name          = "alias/dlq-kms-key"
  target_key_id = aws_kms_key.dlq.id
}

resource "aws_kms_key" "unhandled_events" {
  description = "Custom KMS Key to enable server side encryption unhandled events"
  policy      = data.aws_iam_policy_document.kms_key_policy_doc.json
  enable_key_rotation = true

  tags = {
    Name        = "${var.environment}-unhandled-events-encryption-kms-key"
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}

resource "aws_kms_alias" "unhandled_events" {
  name          = "alias/unhandled-events-kms-key"
  target_key_id = aws_kms_key.unhandled_events.id
}

resource "aws_kms_key" "nems_audit" {
  description = "Custom KMS Key to enable server side encryption continuity nems audit"
  policy      = data.aws_iam_policy_document.kms_key_policy_doc.json
  enable_key_rotation = true

  tags = {
    Name        = "${var.environment}-nems-audit-encryption-kms-key"
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}

resource "aws_kms_alias" "nems_audit" {
  name          = "alias/nems-audit-kms-key"
  target_key_id = aws_kms_key.nems_audit.id
}

#re-registrations
resource "aws_kms_key" "re_registrations" {
  description = "Custom KMS Key to enable server side encryption for Re-registrations Events"
  policy      = data.aws_iam_policy_document.kms_key_policy_doc.json
  enable_key_rotation = true

  tags = {
    Name        = "${var.environment}-sns-sqs-kms-key"
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}

resource "aws_kms_alias" "re_registrations_encryption" {
  name          = "alias/re-registrations-kms-key"
  target_key_id = aws_kms_key.re_registrations.id
}

resource "aws_ssm_parameter" "re_registrations_kms_key_id" {
  name  = "/repo/${var.environment}/output/${var.repo_name}/re-registrations-kms-key-id"
  type  = "String"
  value = aws_kms_key.re_registrations.id

  tags = {
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}

data "aws_iam_policy_document" "kms_key_policy_doc" {
  statement {
    sid    = "Enable key management through IAM while mitigating possible loss of key control"
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

resource "aws_ssm_parameter" "dlq_kms_key_id" {
  name  = "/repo/${var.environment}/output/${var.repo_name}/dlq-kms-key-id"
  type  = "String"
  value = aws_kms_key.dlq.id

  tags = {
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}
