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

resource "aws_iam_role" "component_ecs_role" {
  name               = "${var.environment}-${var.component_name}-EcsTaskRole"
  assume_role_policy = data.aws_iam_policy_document.ecs-assume-role-policy.json
  description        = "Role assumed by ${var.component_name} ECS task"

  tags = {
    Environment = var.environment
    CreatedBy   = var.repo_name
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
      "arn:aws:ssm:${var.region}:${local.account_id}:parameter/repo/${var.environment}/user-input/${var.component_name}-authorization-keys",
      "arn:aws:ssm:${var.region}:${local.account_id}:parameter/repo/${var.environment}/user-input/api-keys/${var.component_name}/*",
      "arn:aws:ssm:${var.region}:${local.account_id}:parameter/repo/${var.environment}/user-input/api-keys/gp2gp-messenger/${var.component_name}",
      "arn:aws:ssm:${var.region}:${local.account_id}:parameter/repo/${var.environment}/user-input/api-keys/ehr-repo/${var.component_name}",
      "arn:aws:ssm:${var.region}:${local.account_id}:parameter/repo/${var.environment}/user-input/ehr-repo-authorization-keys",
      "arn:aws:ssm:${var.region}:${local.account_id}:parameter/repo/${var.environment}/user-input/gp2gp-messenger-authorization-keys",
      "arn:aws:ssm:${var.region}:${local.account_id}:parameter/repo/${var.environment}/user-input/${var.component_name}-db-password",
      "arn:aws:ssm:${var.region}:${local.account_id}:parameter/repo/${var.environment}/user-input/${var.component_name}-db-username"
    ]
  }
}

data "aws_iam_policy_document" "sqs_policy_doc" {
  statement {
    actions = [
      "sqs:GetQueue*",
      "sqs:ChangeMessageVisibility",
      "sqs:DeleteMessage",
      "sqs:ReceiveMessage"
    ]
    resources = [
      aws_sqs_queue.service_incoming.arn
    ]
  }
}

data "aws_iam_policy_document" "kms_policy_doc" {
  statement {
    actions = [
      "kms:Decrypt"
    ]
    resources = [
      aws_kms_key.service_incoming.arn
    ]
  }
}

data "aws_iam_policy_document" "dynamodb_policy_doc" {
  statement {
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:Query"
    ]
    resources = [
      "arn:aws:dynamodb:${var.region}:${data.aws_caller_identity.current.account_id}:table/${var.environment}-ehr-transfer-tracker"
    ]
  }
}

data "aws_iam_policy_document" "transfer_tracker_indexes_access" {
  statement {
    actions = [
      "dynamodb:Query"
    ]
    resources = [
      "arn:aws:dynamodb:${var.region}:${data.aws_caller_identity.current.account_id}:table/${var.environment}-ehr-transfer-tracker/index/*"
    ]
  }
}

resource "aws_iam_policy" "transfer_tracker_indexes_access" {
  name   = "${var.environment}-${var.component_name}-transfer-tracker-indexes-access"
  policy = data.aws_iam_policy_document.transfer_tracker_indexes_access.json
}

resource "aws_iam_role_policy_attachment" "ecs_dynamo_indexes" {
  role       = aws_iam_role.component_ecs_role.name
  policy_arn = aws_iam_policy.transfer_tracker_indexes_access.arn
}

resource "aws_iam_policy" "ssm_policy" {
  name   = "${var.environment}-${var.component_name}-ssm"
  policy = data.aws_iam_policy_document.ssm_policy_doc.json
}

resource "aws_iam_policy" "ecr_policy" {
  name   = "${var.environment}-${var.component_name}-ecr"
  policy = data.aws_iam_policy_document.ecr_policy_doc.json
}

resource "aws_iam_policy" "logs_policy" {
  name   = "${var.environment}-${var.component_name}-logs"
  policy = data.aws_iam_policy_document.logs_policy_doc.json
}

resource "aws_iam_policy" "kms_policy" {
  name   = "${var.environment}-${var.component_name}-kms"
  policy = data.aws_iam_policy_document.kms_policy_doc.json
}

resource "aws_iam_policy" "sqs_policy" {
  name   = "${var.environment}-${var.component_name}-sqs"
  policy = data.aws_iam_policy_document.sqs_policy_doc.json
}

resource "aws_iam_policy" "dynamodb_policy" {
  name   = "${var.environment}-${var.component_name}-dynamodb"
  policy = data.aws_iam_policy_document.dynamodb_policy_doc.json
}

resource "aws_iam_role_policy_attachment" "ssm_policy_attach" {
  role       = aws_iam_role.component_ecs_role.name
  policy_arn = aws_iam_policy.ssm_policy.arn
}

resource "aws_iam_role_policy_attachment" "ecr_policy_attach" {
  role       = aws_iam_role.component_ecs_role.name
  policy_arn = aws_iam_policy.ecr_policy.arn
}

resource "aws_iam_role_policy_attachment" "logs_policy_attach" {
  role       = aws_iam_role.component_ecs_role.name
  policy_arn = aws_iam_policy.logs_policy.arn
}

resource "aws_iam_role_policy_attachment" "sqs_policy_attach" {
  role       = aws_iam_role.component_ecs_role.name
  policy_arn = aws_iam_policy.sqs_policy.arn
}

resource "aws_iam_role_policy_attachment" "kms_policy_attach" {
  role       = aws_iam_role.component_ecs_role.name
  policy_arn = aws_iam_policy.kms_policy.arn
}

resource "aws_iam_role_policy_attachment" "dynamodb_policy_attach" {
  role       = aws_iam_role.component_ecs_role.name
  policy_arn = aws_iam_policy.dynamodb_policy.arn
}


resource "aws_sqs_queue_policy" "ehr_out_service_incoming" {
  queue_url = aws_sqs_queue.service_incoming.id
  policy    = data.aws_iam_policy_document.ehr_out_service_incoming_policy_doc.json
}

data "aws_iam_policy_document" "ehr_out_service_incoming_policy_doc" {
  statement {
    effect = "Allow"

    actions = [
      "sqs:SendMessage"
    ]

    principals {
      identifiers = ["sns.amazonaws.com"]
      type        = "Service"
    }

    resources = [aws_sqs_queue.service_incoming.arn]

    condition {
      test     = "ArnEquals"
      values   = [data.aws_ssm_parameter.ehr_in_unhandled_sns_topic_arn.value]
      variable = "aws:SourceArn"
    }
  }
}