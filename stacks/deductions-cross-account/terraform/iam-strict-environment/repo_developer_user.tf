resource "aws_iam_role" "repo_developer" {
  name = "RepoDeveloper"
  assume_role_policy = data.aws_iam_policy_document.strict_env_trust_policy.json
}

resource "aws_iam_policy" "terraform_plan_permissions_policy" {
  name = "terraform_plan_permissions_policy"
  policy = data.aws_iam_policy_document.terraform_plan_permissions.json
}

data "aws_iam_policy_document" "terraform_plan_permissions" {
  statement {
    effect = "Allow"
    actions = ["ssm:PutParameter*"]
    resources = [
      "arn:aws:ssm:eu-west-2:${data.aws_caller_identity.current.account_id}:parameter/repo/user-input/ssh-*",
      "arn:aws:ssm:eu-west-2:${data.aws_caller_identity.current.account_id}:parameter/repo/user-input/dns-ssh-*"
    ]
  }

  statement {
    effect = "Allow"
    actions = ["ssm:GetParameter*"]
    resources = [
      "arn:aws:ssm:eu-west-2:${data.aws_caller_identity.current.account_id}:parameter/repo/*/output/*",
      "arn:aws:ssm:eu-west-2:${data.aws_caller_identity.current.account_id}:parameter/repo/output/*",
      "arn:aws:ssm:eu-west-2:${data.aws_caller_identity.current.account_id}:parameter/repo/*/user-input/*",
      "arn:aws:ssm:eu-west-2:${data.aws_caller_identity.current.account_id}:parameter/repo/user-input/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "dynamodb:PutItem",
      "dynamodb:DeleteItem",
      "dynamodb:GetItem*",
      "dynamodb:List*",
      "dynamodb:Describe*"
    ]
    resources = ["arn:aws:dynamodb:eu-west-2:${data.aws_caller_identity.current.account_id}:table/prm-deductions-${var.environment}-terraform-table"]
  }

  statement {
    effect = "Allow"
    actions = [
      "dynamodb:Describe*",
      "dynamodb:List*"
    ]
    resources = ["arn:aws:dynamodb:eu-west-2:${data.aws_caller_identity.current.account_id}:table/${var.environment}-repo-mhs*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:Describe*",
      "logs:List*",
      "ec2:Describe*",
      "ssm:Describe*",
      "ssm:List*",
      "rds:Describe*",
      "rds:List*",
      "route53:List*",
      "route53:GetTrafficPolicyInstanceCount",
      "route53:GetHealthCheckCount",
      "route53domains:ListDomains",
      "route53domains:ListOperations",
      "route53:GetHostedZoneCount",
      "route53-recovery-readiness:ListReadinessChecks",
      "route53-recovery-control-config:ListControlPanels",
      "route54:GetHostedZone",
      "acm:Describe*",
      "acm:List*",
      "elasticloadbalancing:Describe*",
      "iam:List*",
      "ecr:DescribeRepositories",
      "mq:Describe*",
      "ecs:Describe*",
      "ecr:ListTagsForResource",
      "elasticache:Describe*",
      "elasticache:List*",
      "sns:GetSubscriptionAttributes"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = ["iam:GetInstanceProfile"]
    resources = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:instance-profile/*"]
  }

  statement {
    effect = "Allow"
    actions =  ["iam:GetRole"]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/*",
      "arn:aws:iam::${data.aws_ssm_parameter.ci_account_id.value}:role/CiReadOnly"
    ]
  }

  statement {
    effect = "Allow"
    actions =  ["iam:GetPolicy", "iam:GetPolicyVersion"]
    resources = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/*"]
  }

  statement {
    effect = "Allow"
    actions =  ["iam:GetRolePolicy"]
    resources = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/*"]
  }

  statement {
    effect = "Allow"
    actions =  ["route53:GetHostedZone"]
    resources = ["arn:aws:route53:::hostedzone/*"]
  }

  statement {
    effect = "Allow"
    actions =  ["sts:AssumeRole"]
    resources = ["arn:aws:iam::${data.aws_ssm_parameter.ci_account_id.value}:role/CiReadOnly"]
  }

  statement {
    effect = "Allow"
    actions = ["ecs:DescribeServices",]
    resources = ["arn:aws:ecs:eu-west-2:${data.aws_caller_identity.current.account_id}:service/${var.environment}*-ecs-cluster/${var.environment}*-service"]
  }

  statement {
    effect = "Allow"
    actions = ["kms:GetKeyRotationStatus",
      "kms:GetKeyPolicy",
      "kms:ListResourceTags",
      "kms:Describe*"
    ]
    resources = ["arn:aws:kms:eu-west-2:${data.aws_caller_identity.current.account_id}:key/*"]
  }

  statement {
    effect = "Allow"
    actions = ["ecs:DescribeClusters", "ecs:ListAttributes", "ecs:ListClusters", "ecs:ListContainerInstances",
      "ecs:ListServices", "ecs:ListTaskDefinitionFamilies", "ecs:ListTaskDefinitions", "ecs:ListTasks"]
    resources = ["arn:aws:ecs:eu-west-2:${data.aws_caller_identity.current.account_id}:*"]
  }

  statement {
    effect = "Allow"
    actions = ["cloudwatch:List*", "cloudwatch:Describe*"]
    resources = ["arn:aws:cloudwatch:eu-west-2:${data.aws_caller_identity.current.account_id}:alarm:*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetResourcePolicy"
    ]
    resources = ["arn:aws:secretsmanager:eu-west-2:${data.aws_caller_identity.current.account_id}:secret:/repo/${var.environment}/user-input/*"]
  }

  statement {
    effect = "Allow"
    sid = "AbilityToRaiseSupportCases"
    actions = ["support:*"]
    resources = ["*"]
  }
}


resource "aws_iam_role_policy_attachment" "terraform_plan_to_repo_developer" {
  policy_arn = aws_iam_policy.terraform_plan_permissions_policy.arn
  role = aws_iam_role.repo_developer.name
}

resource "aws_iam_policy" "aws_console_read" {
  name = "aws_console_read_policy"
  policy = data.aws_iam_policy_document.aws_console_read.json
}

resource "aws_iam_role_policy_attachment" "aws_console_read" {
  policy_arn = aws_iam_policy.aws_console_read.arn
  role = aws_iam_role.repo_developer.name
}

resource "aws_iam_role_policy_attachment" "sqs_read_only_to_repo_developer" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSQSReadOnlyAccess"
  role = aws_iam_role.repo_developer.name
}

resource "aws_iam_role_policy_attachment" "cloudwatch_readonly_access_to_repo_developer" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess"
  role = aws_iam_role.repo_developer.name
}

resource "aws_iam_role_policy_attachment" "repo_developer_s3_allow_terraform_state_content_access" {
  policy_arn = aws_iam_policy.s3_allow_terraform_state_content_access.arn
  role = aws_iam_role.repo_developer.name
}

resource "aws_iam_role_policy_attachment" "repo_developer_s3_allow_ehr_repo_content_access" {
  policy_arn = aws_iam_policy.s3_allow_ehr_repo_content_access.arn
  role = aws_iam_role.repo_developer.name
}

resource "aws_iam_role_policy_attachment" "repo_developer_s3_allow_ehr_repo_bucket_access" {
  policy_arn = aws_iam_policy.s3_allow_ehr_repo_log_bucket_access.arn
  role = aws_iam_role.repo_developer.name
}

resource "aws_iam_role_policy_attachment" "repo_developer_s3_allow_list_buckets" {
  policy_arn = aws_iam_policy.s3_allow_list_buckets.arn
  role = aws_iam_role.repo_developer.name
}

data "aws_iam_policy_document" "aws_console_read" {
  statement {
    effect = "Allow"
    actions = [
      "ecs:ListAttributes",
      "ecs:ListClusters",
      "ecs:ListContainerInstances",
      "ecs:ListServices",
      "ecs:ListTaskDefinitionFamilies",
      "ecs:ListTaskDefinitions",
      "ecs:ListTasks"]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:ListSecrets"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy_attachment" "sns_read_only_access_repo_dev" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSNSReadOnlyAccess"
  role = aws_iam_role.repo_developer.name
}