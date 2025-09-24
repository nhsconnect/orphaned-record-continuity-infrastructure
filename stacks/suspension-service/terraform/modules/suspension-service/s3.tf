locals {
  ingestion_bucket_name = "${var.environment}-ehr-ingestion"
}

resource "aws_s3_bucket" "ingestion_bucket" {
  bucket = local.ingestion_bucket_name

  tags = {
    Name        = local.ingestion_bucket_name
    Environment = var.environment
  }

  lifecycle {
    ignore_changes = [
      logging,
      server_side_encryption_configuration
    ]
  }
}

resource "aws_s3_bucket_logging" "ingestion_bucket" {
  bucket = aws_s3_bucket.ingestion_bucket.id

  target_bucket = data.aws_s3_bucket.access_logs.id
  target_prefix = "${local.ingestion_bucket_name}/"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "ingestion_bucket" {
  bucket = aws_s3_bucket.ingestion_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "ingestion_bucket" {
  bucket = aws_s3_bucket.ingestion_bucket.bucket

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "ingestion_bucket_policy" {
  bucket = aws_s3_bucket.ingestion_bucket.id
  policy = jsonencode({
    "Version": "2008-10-17",
    "Statement" : [
      {
        Effect : "Deny",
        Principal : "*",
        Action : "s3:*",
        Resource : "${aws_s3_bucket.ingestion_bucket.arn}/*",
        Condition : {
          Bool : {
            "aws:SecureTransport" : "false"
          }
        }
      }
    ]
    }
  )
}

resource "aws_iam_policy" "ingestion_bucket_get_object_policy" {
  name = "${local.ingestion_bucket_name}_get_object_policy"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:GetObject",
        ],
        "Resource" : ["${aws_s3_bucket.ingestion_bucket.arn}/*"]
      }
    ]
  })
}
