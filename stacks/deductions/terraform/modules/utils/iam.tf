resource "aws_iam_role" "ecs-service-control-role" {
  count = var.environment == "dev" ? 1: 0

  name = "ECSServiceControlRole"

  assume_role_policy = data.aws_iam_policy_document.ecs-service-control-policy.json
  tags = {
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}

data "aws_iam_policy_document" "ecs-service-control-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = [
        "lambda.amazonaws.com"
      ]
    }
  }
}

data "aws_iam_policy_document" "lambda-logs-policy-doc" {
  statement {
    actions = [
      "logs:*"
    ]

    resources = [
        "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/ECSServiceStop:*",
        "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/ECSServiceStart:*"
    ]
  }
}

data "aws_iam_policy_document" "lambda-ecs-policy-doc" {
  statement {
    actions = [
      "ecs:*"
    ]

    resources = [
        "*"
    ]
  }
}

resource "aws_iam_policy" "logs_policy" {
  count = var.environment == "dev" ? 1: 0

  name   = "lambda-logs-policy"
  policy = data.aws_iam_policy_document.lambda-logs-policy-doc.json
}

resource "aws_iam_policy" "ecs_policy" {
  count = var.environment == "dev" ? 1: 0

  name   = "lambda-ecs-policy"
  policy = data.aws_iam_policy_document.lambda-ecs-policy-doc.json
}

resource "aws_iam_role_policy_attachment" "logs_policy_attach" {
  count = var.environment == "dev" ? 1: 0

  role       = aws_iam_role.ecs-service-control-role[0].name
  policy_arn = aws_iam_policy.logs_policy[0].arn
}

resource "aws_iam_role_policy_attachment" "ecs_policy_attach" {
  count = var.environment == "dev" ? 1: 0

  role       = aws_iam_role.ecs-service-control-role[0].name
  policy_arn = aws_iam_policy.ecs_policy[0].arn
}