resource "aws_lambda_function" "stop-ecs-services-lambda" {
  count = var.environment == "dev" ? 1: 0

  filename      = data.archive_file.lambda-zip[0].output_path
  function_name = "ECSServiceStop"
  description = "Sets 'desired count' of Fargate services with the tag/value TurnOffAtNight=TRUE to the value of the DESIRED_COUNT env var"
  role          = aws_iam_role.ecs-service-control-role[0].arn

  source_code_hash = filebase64sha256(data.archive_file.lambda-zip[0].output_path)

   handler       = "ECSServiceControl.lambda_handler"

  runtime = "python3.7"

  environment {
    variables = {
      DESIRED_COUNT_DEV  = 0
      DESIRED_COUNT_TEST = 0
    }
  }

  tags = {
    CreatedBy   = var.repo_name
    Environment = var.environment
  }

  depends_on = [data.archive_file.lambda-zip]
}

resource "aws_lambda_function" "start-ecs-services-lambda" {
  count = var.environment == "dev" ? 1: 0

  filename      = data.archive_file.lambda-zip[0].output_path
  function_name = "ECSServiceStart"
  description = "Sets 'desired count' of Fargate services with the tag/value TurnOffAtNight=TRUE to the value of the DESIRED_COUNT env var"
  role          = aws_iam_role.ecs-service-control-role[0].arn

  source_code_hash = filebase64sha256(data.archive_file.lambda-zip[0].output_path)

   handler       = "ECSServiceControl.lambda_handler"

  runtime = "python3.7"

  environment {
    variables = {
      DESIRED_COUNT_DEV  = 1
      DESIRED_COUNT_TEST = 2
    }
  }

  tags = {
    CreatedBy   = var.repo_name
    Environment = var.environment
  }

  depends_on = [data.archive_file.lambda-zip[0]]
}

data "archive_file" "lambda-zip" {
  count = var.environment == "dev" ? 1: 0

  type        = "zip"
  source_file = "${path.module}/scripts/ECSServiceControl.py"
  output_path = "${path.module}/tmp/lambda.zip"
}