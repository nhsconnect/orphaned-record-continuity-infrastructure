locals {
  receiver_email_arns = split(",", "arn:aws:ses:${var.region}:${local.account_id}:identity/${join(",arn:aws:ses:${var.region}:${local.account_id}:identity/", split(",", data.aws_ssm_parameter.receiver_cost_report_email_id.value))}")
  support_email_arns  = split(",", "arn:aws:ses:${var.region}:${local.account_id}:identity/${join(",arn:aws:ses:${var.region}:${local.account_id}:identity/", split(",", data.aws_ssm_parameter.support_cost_report_email_id.value))}")
  sender_email_arn    = ["arn:aws:ses:${var.region}:${local.account_id}:identity/${data.aws_ssm_parameter.sender_cost_report_email_id.value}"]
}

data "aws_ssm_parameter" "splunk_trusted_principal" {
  name = "/repo/user-input/external/splunk-trusted-principal"
}

resource "aws_iam_role" "splunk_sqs_forwarder" {
  name        = "SplunkSqsForwarder"
  description = "Role to allow repo to integrate with splunk"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = split(",", data.aws_ssm_parameter.splunk_trusted_principal.value)
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "splunk_access_policy_attachment" {
  role       = aws_iam_role.splunk_sqs_forwarder.name
  policy_arn = aws_iam_policy.splunk_access_policy.arn
}

resource "aws_iam_policy" "splunk_access_policy" {
  name   = "splunk_access_policy"
  policy = data.aws_iam_policy_document.splunk_access_policy_document.json
}

data "aws_iam_policy_document" "splunk_access_policy_document" {
  statement {
    effect = "Allow"
    actions = [
      "sqs:GetQueueAttributes",
      "sqs:ListQueues",
      "sqs:ReceiveMessage",
      "sqs:GetQueueUrl",
      "sqs:SendMessage",
      "sqs:DeleteMessage"
    ]
    resources = ["arn:aws:sqs:*:*:*-audit", "arn:aws:sqs:*:*:*-audit-uploader"]
  }
  statement {
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = ["*"]
  }
}

resource "aws_iam_role" "generate-cost-report-role" {
  name        = "GenerateCostReportLambdaExecution"
  description = "Role to generate the cost report"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "generate-cost-report-role-policy" {
  name   = "generate_cost_report"
  policy = data.aws_iam_policy_document.generate_cost_report_lambda_policy_document.json
}

data "aws_iam_policy_document" "generate_cost_report_lambda_policy_document" {
  statement {
    sid = "GetSSMParameter"
    actions = [
      "ssm:GetParameter"
    ]
    resources = [
      "arn:aws:ssm:${var.region}:${local.account_id}:parameter${data.aws_ssm_parameter.sender_cost_report_email_id.name}",
      "arn:aws:ssm:${var.region}:${local.account_id}:parameter${data.aws_ssm_parameter.receiver_cost_report_email_id.name}",
      "arn:aws:ssm:${var.region}:${local.account_id}:parameter${data.aws_ssm_parameter.support_cost_report_email_id.name}"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]
    resources = [
      "arn:aws:s3:::${var.environment}-cost-and-usage/reports/aws-cost-report/manual-test-results",
      "arn:aws:s3:::${var.environment}-cost-and-usage/reports/aws-cost-report/manual-test-results/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]
    resources = [
      "arn:aws:s3:::${var.environment}-cost-and-usage",
      "arn:aws:s3:::${var.environment}-cost-and-usage/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "athena:StartQueryExecution",
      "athena:GetQueryResults",
      "athena:GetQueryExecution",
      "glue:GetPartitions",
      "glue:GetTable",
      "glue:GetPartition",
      "glue:GetDatabase",
      "glue:GetDatabases"
    ]

    resources = [
      "arn:aws:athena:${var.region}:${local.account_id}:workgroup/primary",
      "arn:aws:glue:${var.region}:${local.account_id}:table/${var.environment}-generate-cost-report-catalog-database/aws_cost_report",
      "arn:aws:glue:${var.region}:${local.account_id}:database/${var.environment}-generate-cost-report-catalog-database",
      "arn:aws:glue:${var.region}:${local.account_id}:catalog"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "ses:SendRawEmail",
      "ses:SendEmail"
    ]
    resources = concat(local.receiver_email_arns, local.sender_email_arn, local.support_email_arns)

  }

}

resource "aws_iam_role_policy_attachment" "generate-cost-report-policy-attachment" {
  role       = aws_iam_role.generate-cost-report-role.name
  policy_arn = aws_iam_policy.generate-cost-report-role-policy.arn
}