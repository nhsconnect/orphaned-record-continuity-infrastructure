locals {
  # IAM for ECS tasks:
  task_role_arn      = aws_iam_role.mhs.arn
  execution_role_arn = aws_iam_role.mhs-ecs.arn

  resources = [
    data.aws_ssm_parameter.mq-app-username.arn,
    data.aws_ssm_parameter.mq-app-password.arn,
    data.aws_ssm_parameter.amqp-endpoint-0.arn,
    data.aws_ssm_parameter.amqp-endpoint-1.arn,
    data.aws_ssm_parameter.party-key.arn,
    data.aws_ssm_parameter.client-cert.arn,
    data.aws_ssm_parameter.client-key.arn,
    data.aws_ssm_parameter.outbound-ca-certs.arn,
    data.aws_ssm_parameter.sds_api_url.arn,
    data.aws_ssm_parameter.sds_api_key.arn
  ]
}

data "aws_iam_policy_document" "mhs-ecs-assume-role-policy" {
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

resource "aws_iam_role" "mhs-ecs" {
  name               = "mhs-${var.environment}-${var.cluster_name}-EcsTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.mhs-ecs-assume-role-policy.json
  tags = {
    Environment = var.environment
    CreatedBy   = var.repo_name
  }
}

data "aws_iam_policy_document" "read-secrets" {
  statement {
    actions = [
      "ssm:Get*",
    ]
    resources = local.resources
  }

  statement {
    actions = [
      "secretsmanager:GetSecretValue",
    ]

    resources = [
      data.aws_secretsmanager_secret.inbound-ca-certs.arn
    ]
  }
}

resource "aws_iam_policy" "read-secrets" {
  name   = "mhs-${var.environment}-${var.cluster_name}-read-secrets"
  policy = data.aws_iam_policy_document.read-secrets.json
}

resource "aws_iam_role_policy_attachment" "ecs-read-secrets-attach" {
  role       = aws_iam_role.mhs-ecs.name
  policy_arn = aws_iam_policy.read-secrets.arn
}

resource "aws_iam_policy" "ecr_policy" {
  name   = "mhs-${var.environment}-${var.cluster_name}-ecr"
  policy = data.aws_iam_policy_document.ecr_policy_doc.json
}

resource "aws_iam_policy" "logs_policy" {
  name   = "mhs-${var.environment}-${var.cluster_name}-logs"
  policy = data.aws_iam_policy_document.logs_policy_doc.json
}

data "aws_iam_policy_document" "ecr_policy_doc" {
  statement {
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage"
    ]

    resources = [
      "arn:aws:ecr:${var.region}:${local.account_id}:repository/docker-hub/*"

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
      "arn:aws:logs:${var.region}:${local.account_id}:log-group:/ecs/${var.environment}-${var.cluster_name}-mhs-*"
    ]
  }
}

resource "aws_iam_role_policy_attachment" "ecr_policy_attach" {
  role       = aws_iam_role.mhs-ecs.name
  policy_arn = aws_iam_policy.ecr_policy.arn
}

resource "aws_iam_role_policy_attachment" "logs_policy_attach" {
  role       = aws_iam_role.mhs-ecs.name
  policy_arn = aws_iam_policy.logs_policy.arn
}

data "aws_iam_policy_document" "ecs-assume-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = [
        "ecs.amazonaws.com",
        "ecs-tasks.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role" "mhs" {
  name               = "mhs-${var.environment}-${var.cluster_name}"
  assume_role_policy = data.aws_iam_policy_document.ecs-assume-role-policy.json
  tags = {
    Environment = var.environment
    CreatedBy   = var.repo_name
  }
}

data "aws_iam_policy_document" "dynamodb-table-access" {
  statement {
    actions = [
      "dynamodb:*"
    ]

    resources = [
      "arn:aws:dynamodb:${var.region}:${data.aws_caller_identity.current.account_id}:table/${var.environment}-${var.cluster_name}-mhs-state",
      "arn:aws:dynamodb:${var.region}:${data.aws_caller_identity.current.account_id}:table/${var.environment}-${var.cluster_name}-mhs-sync-async-state"
    ]
  }
}

resource "aws_iam_policy" "dynamodb-table-access" {
  name   = "mhs-${var.environment}-${var.cluster_name}-dynamodb-table-access"
  policy = data.aws_iam_policy_document.dynamodb-table-access.json
}

resource "aws_iam_role_policy_attachment" "mhs_dynamo_attach" {
  role       = aws_iam_role.mhs.name
  policy_arn = aws_iam_policy.dynamodb-table-access.arn
}
