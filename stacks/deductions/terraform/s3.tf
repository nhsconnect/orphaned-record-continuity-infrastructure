locals {
  cost_usage_access_logs_prefix = "access-logs/"
}

resource "aws_s3_bucket" "cost_and_usage_bucket" {
  bucket = "${var.environment}-cost-and-usage"

  tags = {
    CreatedBy   = var.repo_name
    Environment = var.environment
  }

  lifecycle {
    ignore_changes = [
      logging,
      server_side_encryption_configuration
    ]
  }
}

resource "aws_s3_bucket_logging" "cost_and_usage_bucket" {
  bucket = aws_s3_bucket.cost_and_usage_bucket.id

  target_bucket = aws_s3_bucket.cost_and_usage_access_logs.id
  target_prefix = local.cost_usage_access_logs_prefix
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cost_and_usage_bucket" {
  bucket = aws_s3_bucket.cost_and_usage_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_policy" "allow_access_from_billing_to_s3" {
  bucket = aws_s3_bucket.cost_and_usage_bucket.id
  policy = data.aws_iam_policy_document.allow_access_from_billing_to_s3.json
}

resource "aws_s3_bucket_public_access_block" "cost_and_usage_bucket" {
  bucket = aws_s3_bucket.cost_and_usage_bucket.bucket

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "allow_access_from_billing_to_s3" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["billingreports.amazonaws.com"]
    }
    effect    = "Allow"
    actions   = ["s3:GetBucketAcl", "s3:GetBucketPolicy"]
    resources = [aws_s3_bucket.cost_and_usage_bucket.arn]
  }

  statement {
    sid    = "Stmt1335892526596"
    effect = "Allow"
    principals {
      identifiers = ["billingreports.amazonaws.com"]
      type        = "Service"
    }
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.cost_and_usage_bucket.arn}/*"]
  }

  statement {
    sid    = "S3EnforceHTTPSPolicy"
    effect = "Deny"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions   = ["s3:*"]
    resources = ["${aws_s3_bucket.cost_and_usage_bucket.arn}/*", aws_s3_bucket.cost_and_usage_bucket.arn]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket" "cost_and_usage_access_logs" {
  bucket = "${var.environment}-cost-and-usage-access-logs"

  tags = {
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}

resource "aws_s3_bucket_public_access_block" "cost_and_usage_access_logs" {
  bucket = aws_s3_bucket.cost_and_usage_access_logs.bucket

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "cost_usage_permit_developer_to_see_access_logs_policy" {
  count  = var.is_restricted_account ? 1 : 0
  bucket = aws_s3_bucket.cost_and_usage_access_logs.id
  policy = jsonencode({
    "Version" : "2008-10-17",
    "Statement" : [
      {
        Effect : "Allow",
        Principal : {
          "AWS" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/RepoDeveloper"
        },
        Action : ["s3:Get*", "s3:ListBucket"],
        Resource : [
          "${aws_s3_bucket.cost_and_usage_access_logs.arn}",
          "${aws_s3_bucket.cost_and_usage_access_logs.arn}/*"
        ],
        Condition : {
          Bool : {
            "aws:SecureTransport" : "false"
          }
        }
      }
    ]
  })
}

resource "aws_s3_bucket_policy" "cost_usage_permit_s3_to_write_access_logs_policy" {
  bucket = aws_s3_bucket.cost_and_usage_access_logs.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "S3ServerAccessLogsPolicy",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "logging.s3.amazonaws.com"
        },
        "Action" : "s3:PutObject",
        "Resource" : "${aws_s3_bucket.cost_and_usage_access_logs.arn}/${local.cost_usage_access_logs_prefix}*",
        Condition : {
          Bool : {
            "aws:SecureTransport" : "false"
          }
        }
      },
      {
        "Sid" : "S3EnforceHTTPSPolicy",
        "Effect" : "Deny",
        "Principal" : "*",
        "Action" : "s3:*",
        "Resource" : [
          aws_s3_bucket.cost_and_usage_access_logs.arn,
          "${aws_s3_bucket.cost_and_usage_access_logs.arn}/*"
        ],
        "Condition" : {
          "Bool" : {
            "aws:SecureTransport" : "false"
          }
        }
      }
    ]
  })
}

resource "aws_s3_bucket" "alb_access_logs" {
  bucket = "${var.environment}-repo-load-balancer-access-logs"

  tags = {
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}

resource "aws_s3_bucket_versioning" "alb_access_logs" {
  count = var.s3_backup_enabled ? 1 : 0

  bucket = aws_s3_bucket.alb_access_logs.bucket

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_policy" "alb_access_logs_policy" {
  bucket = aws_s3_bucket.alb_access_logs.id
  policy = data.aws_iam_policy_document.deny_load_balancers_to_publish_to_access_logs_s3_bucket.json
}

resource "aws_s3_bucket_public_access_block" "alb_access_logs" {
  bucket = aws_s3_bucket.alb_access_logs.bucket

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "deny_load_balancers_to_publish_to_access_logs_s3_bucket" {
  statement {
    effect = "Deny"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.alb_access_logs.arn,
      "${aws_s3_bucket.alb_access_logs.arn}/*"
    ]
  }
}

resource "aws_ssm_parameter" "alb_access_logs_s3_bucket_id" {
  value       = aws_s3_bucket.alb_access_logs.id
  type        = "String"
  description = "Exported this bucket id so each alb in different git repos can configure logs"
  name        = "/repo/${var.environment}/output/${var.repo_name}/alb-access-logs-s3-bucket-id"
}

resource "aws_s3_bucket" "access_logs" {
  bucket = "${var.environment}-orc-access-logs"

  force_destroy = true

  tags = {
    CreatedBy   = var.repo_name
    Environment = var.environment
  }

  lifecycle {
    ignore_changes = [server_side_encryption_configuration]
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "access_logs" {
  bucket = aws_s3_bucket.access_logs.bucket

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_policy" "access_logs_permit_s3_to_write_access_logs" {
  bucket = aws_s3_bucket.access_logs.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "S3ServerAccessLogsPolicy",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "logging.s3.amazonaws.com"
        },
        "Action" : "s3:PutObject",
        "Resource" : "${aws_s3_bucket.access_logs.arn}/*",
        Condition : {
          Bool : {
            "aws:SecureTransport" : "false"
          }
        }
      },
      {
        "Sid" : "S3EnforceHTTPSPolicy",
        "Effect" : "Deny",
        "Principal" : "*",
        "Action" : "s3:*",
        "Resource" : [
          aws_s3_bucket.access_logs.arn,
          "${aws_s3_bucket.access_logs.arn}/*"
        ],
        "Condition" : {
          "Bool" : {
            "aws:SecureTransport" : "false"
          }
        }
      }
    ]
  })
}

resource "aws_s3_bucket_public_access_block" "access_logs" {
  bucket = aws_s3_bucket.access_logs.bucket

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
