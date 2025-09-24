resource "aws_glue_catalog_database" "generate_cost_report_database" {
  name = "${var.environment}-generate-cost-report-catalog-database"
}

resource "aws_glue_crawler" "generate_cost_report_crawler" {
  database_name = aws_glue_catalog_database.generate_cost_report_database.name
  name          = "${var.environment}-generate-cost-report-crawler"
  role          = aws_iam_role.generate_cost_report_glue_role.arn
  schedule      = "cron(0 8 8 * ? *)"
  s3_target {
    path = "s3://${aws_s3_bucket.cost_and_usage_bucket.bucket}/reports/aws-cost-report/aws-cost-report/"
  }
}

resource "aws_iam_role" "generate_cost_report_glue_role" {
  name               = "${var.environment}-generate-cost-report-glue-role"
  description        = "Glue Role to allow access to the billing reports"
  assume_role_policy = data.aws_iam_policy_document.generate_cost_report_glue_assume_role_policy.json
}

resource "aws_iam_policy" "generate_cost_report_glue_role_policy" {
  name   = "generate_cost_report_glue_role_policy"
  policy = data.aws_iam_policy_document.generate_cost_report_glue_policy_document.json
}

data "aws_iam_policy_document" "generate_cost_report_glue_policy_document" {
  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]
    resources = [
      "arn:aws:s3:::${var.environment}-cost-and-usage/reports/aws-cost-report/*"
    ]
  }
}

data "aws_iam_policy_document" "generate_cost_report_glue_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = [
        "glue.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role_policy_attachment" "generate_cost_report_glue_attachment" {
  for_each = toset([
    format("arn:aws:iam::%s:policy/%s", data.aws_caller_identity.current.account_id, aws_iam_policy.generate_cost_report_glue_role_policy.name),
    "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole",
  ])

  role       = aws_iam_role.generate_cost_report_glue_role.name
  policy_arn = each.value
}