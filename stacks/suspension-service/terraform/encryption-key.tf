resource "aws_kms_key" "not_suspended" {
  description         = "Custom KMS Key to enable server side encryption for SNS and SQS"
  policy              = data.aws_iam_policy_document.kms_key_policy_doc.json
  enable_key_rotation = true

  tags = {
    Name        = "${var.environment}-not-suspended-queue-encryption-kms-key"
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}

resource "aws_kms_alias" "not_suspended_encryption" {
  name          = "alias/${var.component_name}-not-suspended-encryption-kms-key"
  target_key_id = aws_kms_key.not_suspended.id
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

resource "aws_kms_key" "mof_updated" {
  description         = "Custom KMS Key to enable server side encryption for SNS and SQS"
  policy              = data.aws_iam_policy_document.kms_key_policy_doc.json
  enable_key_rotation = true

  tags = {
    Name        = "${var.environment}-mof-updated-queue-encryption-kms-key"
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}

resource "aws_kms_alias" "mof_updated_encryption" {
  name          = "alias/${var.component_name}-mof-updated-encryption-kms-key"
  target_key_id = aws_kms_key.mof_updated.id
}

resource "aws_kms_key" "mof_not_updated" {
  description         = "Custom KMS Key to enable server side encryption for mof not updated topic"
  policy              = data.aws_iam_policy_document.kms_key_policy_doc.json
  enable_key_rotation = true

  tags = {
    Name        = "${var.environment}-mof-not-updated-queue-encryption-kms-key"
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}

resource "aws_kms_alias" "mof_not_updated_encryption" {
  name          = "alias/${var.component_name}-mof-not-updated-encryption-kms-key"
  target_key_id = aws_kms_key.mof_not_updated.id
}

resource "aws_kms_key" "invalid_suspension" {
  description         = "Custom KMS Key to enable server side encryption for invalid suspension topic"
  policy              = data.aws_iam_policy_document.kms_key_policy_doc.json
  enable_key_rotation = true

  tags = {
    Name        = "${var.environment}-invalid-suspension-kms-key"
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}

resource "aws_kms_alias" "invalid_suspension_encryption" {
  name          = "alias/${var.component_name}-invalid-suspension-encryption-kms-key"
  target_key_id = aws_kms_key.invalid_suspension.id
}

resource "aws_kms_key" "invalid_suspension_audit" {
  description         = "Custom KMS Key to enable server side encryption for invalid suspension audit topic"
  policy              = data.aws_iam_policy_document.kms_key_policy_doc.json
  enable_key_rotation = true

  tags = {
    Name        = "${var.environment}-non-sensitive-invalid-suspension-kms-key"
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}

resource "aws_kms_alias" "invalid_suspension_audit_encryption" {
  name          = "alias/${var.component_name}-non-sensitive-invalid-suspension-encryption-kms-key"
  target_key_id = aws_kms_key.invalid_suspension_audit.id
}

resource "aws_kms_key" "event_out_of_order" {
  description         = "Custom KMS Key to enable server side encryption for event out of order topic"
  policy              = data.aws_iam_policy_document.kms_key_policy_doc.json
  enable_key_rotation = true

  tags = {
    Name        = "${var.environment}-event-out-of-order-kms-key"
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}

resource "aws_kms_alias" "event_out_of_order_encryption" {
  name          = "alias/${var.component_name}-event-out-of-order-encryption-kms-key"
  target_key_id = aws_kms_key.event_out_of_order.id
}

resource "aws_kms_key" "suspension_dynamodb_kms_key" {
  description         = "Custom KMS Key to enable server side encryption for Suspension DB"
  policy              = data.aws_iam_policy_document.kms_key_policy_doc.json
  enable_key_rotation = true

  tags = {
    Name        = "${var.environment}-${var.component_name}-dynamodb-kms-key"
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}

resource "aws_kms_alias" "suspension_dynamodb_encryption" {
  name          = "alias/${var.component_name}-suspension-dynamodb-encryption-kms-key"
  target_key_id = aws_kms_key.suspension_dynamodb_kms_key.id
}

resource "aws_kms_key" "deceased_patient" {
  description         = "Custom KMS Key to enable server side encryption for deceased patient topic"
  policy              = data.aws_iam_policy_document.kms_key_policy_doc.json
  enable_key_rotation = true

  tags = {
    Name        = "${var.environment}-deceased-patient-kms-key"
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}

resource "aws_kms_alias" "deceased_patient_encryption" {
  name          = "alias/${var.component_name}-deceased-patient-encryption-kms-key"
  target_key_id = aws_kms_key.deceased_patient.id
}

resource "aws_kms_key" "active_suspensions" {
  description         = "Custom KMS Key to enable server side encryption for active-suspensions topic"
  policy              = data.aws_iam_policy_document.kms_key_policy_doc.json
  enable_key_rotation = true

  tags = {
    Name        = "${var.environment}-active-suspensions-encryption-kms-key"
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}

resource "aws_kms_alias" "active_suspensions_encryption" {
  name          = "alias/${var.component_name}-active-suspensions-encryption-kms-key"
  target_key_id = aws_kms_key.active_suspensions.id
}