locals {
  ingestion_lambda_name = "orc_ingestion"
  iam_role_policies = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
    "arn:aws:iam::aws:policy/CloudWatchLambdaInsightsExecutionRolePolicy",
    aws_iam_policy.suspensions_queue_send_message_policy.arn,
    aws_iam_policy.ingestion_bucket_get_object_policy.arn
  ]
}

resource "aws_lambda_function" "lambda" {
  filename         = data.archive_file.lambda.output_path
  function_name    = "${var.environment}_${local.ingestion_lambda_name}"
  role             = aws_iam_role.lambda_execution_role.arn
  handler          = "${local.ingestion_lambda_name}.lambda_handler"
  source_code_hash = data.archive_file.lambda.output_base64sha256
  runtime     = "python3.12"
  timeout     = 30
  memory_size = 128

  environment {
    variables = {
      SUSPENSION_QUEUE_URL = aws_sqs_queue.suspensions.id
      S3_BUCKET_NAME       = aws_s3_bucket.ingestion_bucket.id
      INGEST_FILE_NAME     = "Patient-List-Test"
    }
  }
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda_execution_role" {
  name               = "${var.environment}_lambda_execution_role_${local.ingestion_lambda_name}"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "lambda_execution_policy" {
  count      = length(local.iam_role_policies)
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = local.iam_role_policies[count.index]
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "../lambdas/${local.ingestion_lambda_name}/${local.ingestion_lambda_name}.py"
  output_path = "../lambdas/${local.ingestion_lambda_name}/${local.ingestion_lambda_name}_payload.zip"
}
