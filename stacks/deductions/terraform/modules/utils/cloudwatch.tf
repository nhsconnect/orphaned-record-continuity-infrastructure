resource "aws_cloudwatch_event_rule" "morning-mon-fri" {
  count = var.environment == "dev" ? 1: 0

  name                = "Morning-Monday-to-Friday"
  description         = "Fires 7am Monday to Friday"
  schedule_expression = "cron(0 7 ? * MON-FRI *)"
  tags = {
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}

resource "aws_cloudwatch_event_rule" "evening-mon-fri" {
  count = var.environment == "dev" ? 1: 0

  name                = "Evening-Monday-to-Friday"
  description         = "Fires 8pm Monday to Friday"
  schedule_expression = "cron(0 20 ? * MON-FRI *)"
  tags = {
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}

resource "aws_cloudwatch_event_target" "turn-on-ecs-tasks" {
  count = var.environment == "dev" ? 1: 0

  rule      =  aws_cloudwatch_event_rule.morning-mon-fri[0].name
  target_id = "ECSServiceStart"
  arn       =  aws_lambda_function.start-ecs-services-lambda[0].arn
}

resource "aws_cloudwatch_event_target" "turn-off-ecs-tasks" {
  count = var.environment == "dev" ? 1: 0

  rule      =  aws_cloudwatch_event_rule.evening-mon-fri[0].name
  target_id = "ECSServiceStop"
  arn       =  aws_lambda_function.stop-ecs-services-lambda[0].arn
}

resource "aws_lambda_permission" "allow-cloudwatch-to-turn-on-ecs" {
  count = var.environment == "dev" ? 1: 0

  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.start-ecs-services-lambda[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.morning-mon-fri[0].arn
}

resource "aws_lambda_permission" "allow-cloudwatch-to-turn-off-ecs" {
  count = var.environment == "dev" ? 1: 0

  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.stop-ecs-services-lambda[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.evening-mon-fri[0].arn
}