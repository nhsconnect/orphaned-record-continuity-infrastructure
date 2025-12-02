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

resource "aws_iam_role" "gp2gp" {
  name               = "${var.environment}-${var.component_name}-EcsTaskRole"
  assume_role_policy = data.aws_iam_policy_document.ecs-assume-role-policy.json
  description        = "Role assumed by ${var.component_name} ECS task"

  tags = {
    Environment = var.environment
    CreatedBy   = var.repo_name
  }
}

data "aws_iam_policy_document" "sqs_hl7_observability_policy_doc" {
  statement {
    actions = [
      "sqs:SendMessage"
    ]

    resources = [
      aws_sqs_queue.hl7_message_sent_observability.arn
    ]
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
      "arn:aws:ssm:${var.region}:${local.account_id}:parameter/repo/${var.environment}/user-input/mq-app-username",
      "arn:aws:ssm:${var.region}:${local.account_id}:parameter/repo/${var.environment}/user-input/mq-app-password",
      "arn:aws:ssm:${var.region}:${local.account_id}:parameter/repo/${var.environment}/user-input/${var.component_name}-deductions-asid",
      "arn:aws:ssm:${var.region}:${local.account_id}:parameter/repo/${var.environment}/user-input/${var.component_name}-deductions-ods-code",
      "arn:aws:ssm:${var.region}:${local.account_id}:parameter/repo/${var.environment}/user-input/external/pds-asid",
    ]
  }
}

data "aws_iam_policy_document" "kms_policy_doc" {
  statement {
    actions = [
      "kms:*"
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_policy" "gp2gp-sqs" {
  name   = "${var.environment}-gp2gp-messenger-sqs"
  policy = data.aws_iam_policy_document.sqs_hl7_observability_policy_doc.json
}

resource "aws_iam_policy" "gp2gp-ecr" {
  name   = "${var.environment}-gp2gp-ecr"
  policy = data.aws_iam_policy_document.ecr_policy_doc.json
}

resource "aws_iam_policy" "gp2gp-logs" {
  name   = "${var.environment}-gp2gp-logs"
  policy = data.aws_iam_policy_document.logs_policy_doc.json
}

resource "aws_iam_policy" "gp2gp-ssm" {
  name   = "${var.environment}-gp2gp-ssm"
  policy = data.aws_iam_policy_document.ssm_policy_doc.json
}

resource "aws_iam_policy" "gp2gp_messenger_kms" {
  name   = "${var.environment}-${var.component_name}-kms"
  policy = data.aws_iam_policy_document.kms_policy_doc.json
}

resource "aws_iam_role_policy_attachment" "gp2gp-messenger-sqs-attach" {
  role       = aws_iam_role.gp2gp.name
  policy_arn = aws_iam_policy.gp2gp-sqs.arn
}

resource "aws_iam_role_policy_attachment" "gp2gp-ecr-attach" {
  role       = aws_iam_role.gp2gp.name
  policy_arn = aws_iam_policy.gp2gp-ecr.arn
}

resource "aws_iam_role_policy_attachment" "gp2gp-ssm" {
  role       = aws_iam_role.gp2gp.name
  policy_arn = aws_iam_policy.gp2gp-ssm.arn
}

resource "aws_iam_role_policy_attachment" "gp2gp-logs" {
  role       = aws_iam_role.gp2gp.name
  policy_arn = aws_iam_policy.gp2gp-logs.arn
}

resource "aws_iam_role_policy_attachment" "gp2gp_messenger_kms" {
  role       = aws_iam_role.gp2gp.name
  policy_arn = aws_iam_policy.gp2gp_messenger_kms.arn
}