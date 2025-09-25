resource "aws_iam_role" "bootstrap_admin" {
  name = "BootstrapAdmin"
  assume_role_policy = data.aws_iam_policy_document.strict_env_trust_policy.json
}

resource "aws_iam_policy" "bootstrap_admin_permissions_policy" {
  name = "bootstrap_admin_permissions_policy"
  policy = data.aws_iam_policy_document.bootstrap_admin_permissions.json
}

data "aws_iam_policy_document" "bootstrap_admin_permissions" {
  statement {
    effect = "Allow"
    actions = ["ssm:PutParameter*", "ssm:DeleteParameter*"]
    resources = [
      "arn:aws:ssm:eu-west-2:${data.aws_caller_identity.current.account_id}:parameter/repo/user-input/*",
      "arn:aws:ssm:eu-west-2:${data.aws_caller_identity.current.account_id}:parameter/repo/*/user-input/*",
    ]
  }

  statement {
    effect = "Allow"
    actions = ["ssm:Describe*", "ssm:Get*", "ssm:List*"]
    resources = ["*"]
    }

  statement {
    effect = "Allow"
    actions = [  "sns:GetTopicAttributes", "sns:List*"]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = ["sqs:ListQueueTags", "sns:GetSubscriptionAttributes"]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = ["events:ListRules"]
    resources = ["arn:aws:events:eu-west-2:${data.aws_caller_identity.current.account_id}:rule/*"]
  }

  statement {
    effect = "Allow"
    actions = ["lambda:InvokeFunction"]
    resources = ["arn:aws:lambda:eu-west-2:${data.aws_caller_identity.current.account_id}:function:${var.environment}-generate-cost-report-lambda"]
  }

  statement {
    effect = "Allow"
    actions = [
      "ses:ListIdentities",
      "ses:ListVerifiedEmailAddresses",
      "ses:ListEmailIdentities",
      "ses:VerifyEmailAddress",
      "ses:VerifyEmailIdentity",
      "ses:GetAccount",
      "ses:ListConfigurationSets",
      "ses:CreateEmailIdentity",
      "ses:TagResource",
      "ses:DeleteEmailIdentity"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:CreateSecret",
      "secretsmanager:DescribeSecret",
      "secretsmanager:PutSecretValue",
      "secretsmanager:UpdateSecret"
    ]
    resources = [
      "arn:aws:secretsmanager:eu-west-2:${data.aws_caller_identity.current.account_id}:secret:/repo/${var.environment}/user-input/external/repo-mhs-inbound-ca-certs"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "dynamodb:PutItem*",
      "dynamodb:GetItem*",
      "dynamodb:DeleteItem*",
      "dynamodb:CreateTable",
      "dynamodb:TagResource",
      "dynamodb:DeleteTable",
      "dynamodb:List*",
      "dynamodb:Describe*"
    ]
    resources = ["arn:aws:dynamodb:eu-west-2:${data.aws_caller_identity.current.account_id}:table/prm-deductions-${var.environment}-terraform-table"]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:CreateBucket",
      "s3:DeleteBucket",
      "s3:PutEncryptionConfiguration",
      "s3:PutLifecycleConfiguration",
      "s3:PutBucketPolicy",
      "s3:PutBucketVersioning",
      "s3:PutBucketTagging",
      "s3:PutBucketAcl"
    ]
    resources = [
      "arn:aws:s3:::prm-deductions-${var.state_bucket_infix}terraform-state*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "arn:aws:s3:::prm-deductions-${var.state_bucket_infix}terraform-state/*",
      "arn:aws:s3:::prm-deductions-${var.state_bucket_infix}terraform-state-store/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject"
    ]
    resources = [
      "arn:aws:s3:::${var.environment}-cost-and-usage/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:List*",
      "s3:Get*",
      "s3:PutBucketPolicy"
    ]
    resources = [
      "arn:aws:s3:::${var.environment}-cost-and-usage"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "glue:GetPartitions",
      "glue:GetTable",
      "glue:SearchTables",
      "glue:GetPartition",
      "glue:GetDatabase"
    ]
    resources = [
      "arn:aws:glue:eu-west-2:${data.aws_caller_identity.current.account_id}:table/${var.environment}-generate-cost-report-catalog-database/aws_cost_report",
      "arn:aws:glue:eu-west-2:${data.aws_caller_identity.current.account_id}:database/${var.environment}-generate-cost-report-catalog-database",
      "arn:aws:glue:eu-west-2:${data.aws_caller_identity.current.account_id}:catalog"
    ]
  }

  statement {
    sid = "S3AllowListBuckets"
    effect = "Allow"
    actions = [
      "s3:ListAllMyBuckets",
      "s3:ListAllMyBuckets"
    ]
    resources = [
      "*"
    ]
  }

  statement {
    effect = "Allow"
    actions =  ["ec2:ExportClientVpnClientConfiguration", "ec2:ImportClientVpnClientCertificateRevocationList"]
    resources = ["arn:aws:ec2:eu-west-2:${data.aws_caller_identity.current.account_id}:client-vpn-endpoint/${data.aws_ssm_parameter.client-vpn-endpoint-id.value}"]
  }

  statement {
    effect = "Allow"
    actions =  [
      "iam:CreateRole",
      "iam:AttachRolePolicy",
      "iam:CreateInstanceProfile",
      "iam:AddRoleToInstanceProfile",
      "iam:RemoveRoleFromInstanceProfile",
      "iam:PassRole",
      "iam:CreatePolicy",
      "iam:DeletePolicyVersion",
      "iam:DeleteInstanceProfile",
      "iam:CreatePolicyVersion",
      "iam:DeletePolicy",
      "iam:DeleteRole",
      "iam:DetachRolePolicy"
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/repository-ci-agent",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/Deployer",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/RepoDeveloper",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:instance-profile/repository-ci-agent",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:instance-profile/Deployer",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:instance-profile/RepoDeveloper",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/bootstrap_admin_permissions_policy",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/repo_developer_permissions_policy"]
  }

  statement {
    effect = "Allow"
    actions = [
      "iam:Get*",
      "iam:List*",
      "iam:Generate*"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "kms:ListAliases"
      ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "glue:GetCrawler",
      "glue:GetTables",
      "glue:GetDatabases",
      "glue:GetTable",
      "glue:ListSchemas",
      "glue:SearchTables",
      "glue:GetPartitions",
      "glue:GetDatabase",
      "glue:GetPartition",
      "glue:ListCrawlers",
      "glue:ListCrawls",
      "glue:GetCrawlers"
    ]
    resources = [
      "arn:aws:glue:eu-west-2:${data.aws_caller_identity.current.account_id}:table/${var.environment}-generate-cost-report-catalog-database/aws-cost-report",
      "arn:aws:glue:eu-west-2:${data.aws_caller_identity.current.account_id}:crawler/${var.environment}-generate-cost-report-crawler",
      "arn:aws:glue:eu-west-2:${data.aws_caller_identity.current.account_id}:database/${var.environment}-generate-cost-report-catalog-database",
      "arn:aws:glue:eu-west-2:${data.aws_caller_identity.current.account_id}:catalog",
      "arn:aws:glue:eu-west-2:${data.aws_caller_identity.current.account_id}:catalog/*",
      "arn:aws:glue:eu-west-2:${data.aws_caller_identity.current.account_id}:crawler/*"
    ]
  }
}

data "aws_iam_policy_document" "bootstrap_update_service" {
  statement {
    effect  = "Allow"
    actions = [
      "ecs:ListClusters", "ecs:ListServices", "ecs:ListTaskDefinitionFamilies", "ecs:ListTaskDefinitions",
      "ecs:ListAttributes",
      "ecs:ListServices", "ecs:ListContainerInstances"
    ]
    resources = [
      "*",
    ]
  }

  statement {
    effect  = "Allow"
    actions = [
      "ecs:DescribeCapacityProviders", "ecs:DescribeServices", "ecs:DescribeTaskSets", "ecs:DescribeClusters",
      "ecs:DescribeTaskDefinition",
      "ecs:ListAccountSettings", "ecs:DescribeContainerInstances", "ecs:DescribeTasks", "ecs:ListTagsForResource"
    ]
    resources = [
      "*",
    ]
  }

  statement {
    effect    = "Allow"
    actions   = ["ecs:UpdateService"]
    resources = [
      "arn:aws:ecs:eu-west-2:${data.aws_caller_identity.current.account_id}:service/${var.environment}-suspension-service-ecs-cluster/${var.environment}-suspension-service"
    ]
  }
}

resource "aws_iam_policy" "bootstrap_update_ecs" {
  name = "update-ecs-service"
  policy = data.aws_iam_policy_document.bootstrap_update_service.json
}

resource "aws_iam_role_policy_attachment" "bootstrap_update_service" {
  policy_arn = aws_iam_policy.bootstrap_update_ecs.arn
  role = aws_iam_role.bootstrap_admin.name
}

resource "aws_iam_role_policy_attachment" "bootstrap_admin" {
  for_each = toset([
    aws_iam_policy.bootstrap_admin_permissions_policy.arn,
    "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole",
  ])
  policy_arn = each.value
  role = aws_iam_role.bootstrap_admin.name
}

resource "aws_iam_role_policy_attachment" "terraform_plan_to_bootstrap_admin" {
  policy_arn = aws_iam_policy.terraform_plan_permissions_policy.arn
  role = aws_iam_role.bootstrap_admin.name
}

resource "aws_iam_role_policy_attachment" "sqs_read_only_access" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSQSReadOnlyAccess"
  role = aws_iam_role.bootstrap_admin.name
}

resource "aws_iam_role_policy_attachment" "dynamo_read_only_access" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBReadOnlyAccess"
  role = aws_iam_role.bootstrap_admin.name
}

resource "aws_iam_role_policy_attachment" "lambda_read_only_access" {
  policy_arn = "arn:aws:iam::aws:policy/AWSLambda_ReadOnlyAccess"
  role = aws_iam_role.bootstrap_admin.name
}

resource "aws_iam_role_policy_attachment" "athena_access" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonAthenaFullAccess"
  role = aws_iam_role.bootstrap_admin.name
}

resource "aws_iam_role_policy_attachment" "bootstrap_admin_s3_allow_terraform_state_content_access" {
  policy_arn = aws_iam_policy.s3_allow_terraform_state_content_access.arn
  role = aws_iam_role.bootstrap_admin.name
}

resource "aws_iam_role_policy_attachment" "bootstrap_admin_billing_console_access" {
  policy_arn = aws_iam_policy.bootstrap_admin_billing_console_access.arn
  role = aws_iam_role.bootstrap_admin.name
}

resource "aws_iam_policy" "bootstrap_admin_billing_console_access" {
  name = "${var.environment}-billing-console-access"
  policy = data.aws_iam_policy_document.bootstrap_admin_billing_console_access.json
}

data "aws_iam_policy_document" "bootstrap_admin_billing_console_access" {
  statement {
    effect = "Allow"
    actions = [
      "cur:DescribeReportDefinitions",
      "cur:PutReportDefinition",
      "cur:DeleteReportDefinition",
      "cur:ModifyReportDefinition",
      "aws-portal:ViewBilling",
      "aws-portal:ViewAccount",
      "aws-portal:ViewPaymentMethods",
      "ce:CreateCostCategoryDefinition",
      "ce:DescribeCostCategoryDefinition",
      "ce:ListCostCategoryDefinitions",
      "aws-portal:ViewUsage",
      "pricing:DescribeServices",
      "pricing:GetAttributeValues",
      "pricing:GetProducts"
    ]
    resources = ["*"]
  }
}