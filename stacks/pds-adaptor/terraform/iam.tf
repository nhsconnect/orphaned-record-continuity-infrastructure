locals {
  account_id = data.aws_caller_identity.current.account_id
}

data "aws_iam_policy_document" "ecs-assume-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = [
        "ecs-tasks.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role" "component-ecs-role" {
  name               = "${var.environment}-${var.component_name}-EcsTaskRole"
  assume_role_policy = data.aws_iam_policy_document.ecs-assume-role-policy.json
  description        = "Role assumed by ${var.component_name} ECS task"

  tags = {
    Environment = var.environment
    CreatedBy= var.repo_name
  }
}

data "aws_iam_policy_document" "ecr_policy_doc" {
  statement {
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage"
    ]

    resources = [
      "arn:aws:ecr:${var.region}:${local.account_id}:repository/deductions/${var.component_name}"
    ]
  }

  statement {
    actions = [
      "ecr:GetAuthorizationToken"
    ]

    resources = [
      "*"
    ]
  }
}

data "aws_iam_policy_document" "logs_policy_doc" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      "arn:aws:logs:${var.region}:${local.account_id}:log-group:/nhs/deductions/${var.environment}-${local.account_id}/${var.component_name}:*"
    ]
  }
}

data "aws_iam_policy_document" "ssm_policy_doc" {
  statement {
    actions = [
      "ssm:Get*"
    ]

    resources = [
      "arn:aws:ssm:${var.region}:${local.account_id}:parameter/repo/${var.environment}/user-input/external/pds-adaptor-jwt-private-key",
      "arn:aws:ssm:${var.region}:${local.account_id}:parameter/repo/${var.environment}/user-input/external/pds-adaptor-jwt-api-key",
      "arn:aws:ssm:${var.region}:${local.account_id}:parameter/repo/${var.environment}/user-input/external/pds-adaptor-jwt-key-id",
      "arn:aws:ssm:${var.region}:${local.account_id}:parameter/repo/${var.environment}/user-input/external/pds-adaptor-access-token-endpoint",
      "arn:aws:ssm:${var.region}:${local.account_id}:parameter/repo/${var.environment}/user-input/external/pds-fhir-endpoint",
      "arn:aws:ssm:${var.region}:${local.account_id}:parameter/repo/${var.environment}/user-input/api-keys/pds-adaptor/*"
    ]
  }
}

resource "aws_iam_policy" "ssm_policy" {
  name   = "${var.environment}-${var.component_name}-ssm"
  policy = data.aws_iam_policy_document.ssm_policy_doc.json
}

resource "aws_iam_role_policy_attachment" "ssm_policy_attach" {
  role       = aws_iam_role.component-ecs-role.name
  policy_arn = aws_iam_policy.ssm_policy.arn
}


resource "aws_iam_policy" "ecr_policy" {
  name   = "${var.environment}-${var.component_name}-ecr"
  policy = data.aws_iam_policy_document.ecr_policy_doc.json
}

resource "aws_iam_policy" "logs_policy" {
  name   = "${var.environment}-${var.component_name}-logs"
  policy = data.aws_iam_policy_document.logs_policy_doc.json
}


resource "aws_iam_role_policy_attachment" "ecr_policy_attach" {
  role       = aws_iam_role.component-ecs-role.name
  policy_arn = aws_iam_policy.ecr_policy.arn
}

resource "aws_iam_role_policy_attachment" "logs_policy_attach" {
  role       = aws_iam_role.component-ecs-role.name
  policy_arn = aws_iam_policy.logs_policy.arn
}

