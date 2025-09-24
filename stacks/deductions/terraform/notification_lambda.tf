locals {
  alarm_webhook_ssm_path = "/repo/${var.environment}/user-input/external/alarm-notifications-webhook-url"
  account_id             = data.aws_caller_identity.current.account_id
}

resource "aws_lambda_function" "alarm_notifications_lambda" {
  filename         = var.alarm_lambda_zip
  function_name    = "${var.environment}-alarm-notifications-lambda"
  role             = aws_iam_role.alarm_notifications_lambda_role.arn
  handler          = "main.lambda_handler"
  source_code_hash = filebase64sha256(var.alarm_lambda_zip)
  runtime          = "python3.12"
  timeout          = 15
  tags = {
    Environment = var.environment
    CreatedBy   = var.repo_name
  }
  environment {
    variables = {
      ALARM_WEBHOOK_URL_PARAM_NAME = local.alarm_webhook_ssm_path
    }
  }
}

resource "aws_iam_role" "alarm_notifications_lambda_role" {
  name               = "${var.environment}-alarm-notifications-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "lambda_create_log" {
  role   = aws_iam_role.alarm_notifications_lambda_role.id
  policy = data.aws_iam_policy_document.lambda_create_log.json
}

data "aws_iam_policy_document" "lambda_create_log" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:*:*:*"
    ]
  }
}

data "aws_iam_policy_document" "webhook_ssm_access" {
  statement {
    sid = "GetSSMParameter"

    actions = [
      "ssm:GetParameter"
    ]

    resources = [
      "arn:aws:ssm:${var.region}:${local.account_id}:parameter${local.alarm_webhook_ssm_path}"
    ]
  }
}

resource "aws_iam_policy" "webhook_ssm_access" {
  name   = "${var.environment}-webhook-ssm-access"
  policy = data.aws_iam_policy_document.webhook_ssm_access.json
}

resource "aws_iam_role_policy_attachment" "webhook_ssm_access_attachment" {
  role       = aws_iam_role.alarm_notifications_lambda_role.name
  policy_arn = aws_iam_policy.webhook_ssm_access.arn
}

resource "aws_lambda_permission" "allow_invocation_from_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.alarm_notifications_lambda.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.alarm_notifications.arn
}

resource "aws_sns_topic_subscription" "alarm_notifications_lambda_subscription" {
  topic_arn = aws_sns_topic.alarm_notifications.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.alarm_notifications_lambda.arn
}