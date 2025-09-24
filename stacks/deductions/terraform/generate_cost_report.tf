resource "aws_lambda_function" "generate_cost_report_lambda" {
  filename         = var.generate_cost_report_lambda_zip
  function_name    = "${var.environment}-generate-cost-report-lambda"
  role             = aws_iam_role.generate-cost-report-role.arn
  handler          = "main.lambda_handler"
  source_code_hash = filebase64sha256(var.generate_cost_report_lambda_zip)
  runtime          = "python3.12"
  timeout          = 15
  memory_size      = 448
  tags = {
    Environment = var.environment
    CreatedBy   = var.repo_name
  }
  environment {
    variables = {
      ENVIRONMENT                  = var.environment,
      SENDER_EMAIL_SSM_PARAMETER   = data.aws_ssm_parameter.sender_cost_report_email_id.name,
      RECEIVER_EMAIL_SSM_PARAMETER = data.aws_ssm_parameter.receiver_cost_report_email_id.name
      SUPPORT_EMAIL_SSM_PARAMETER  = data.aws_ssm_parameter.support_cost_report_email_id.name
      ACCOUNT_ID                   = data.aws_caller_identity.current.account_id
      GENERATE_REPORT_FOR_YEAR     = ""
      GENERATE_REPORT_FOR_MONTH    = ""
    }
  }
}

resource "aws_cloudwatch_event_rule" "generate_cost_report_end_of_every_month" {
  name                = "generate-cost-report-end-of-every-month"
  description         = "Invokes cost report lambda function end of every month"
  schedule_expression = "cron(0 9 8 * ? *)"
  tags = {
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}

resource "aws_cloudwatch_event_target" "invoke_generate_cost_report_lambda" {
  rule      = aws_cloudwatch_event_rule.generate_cost_report_end_of_every_month.name
  target_id = "InvokeLambda"
  arn       = aws_lambda_function.generate_cost_report_lambda.arn
}

resource "aws_lambda_permission" "allow_invocation_from_event_bridge_rule" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.generate_cost_report_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.generate_cost_report_end_of_every_month.arn
}