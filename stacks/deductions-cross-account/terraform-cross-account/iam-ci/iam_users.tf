data "aws_caller_identity" "ci_account" {}

data "aws_iam_policy_document" "ci_read_only_trust_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_ssm_parameter.dev_account_id.value}:role/RepoAdmin",              # dev environment (in dev account)
        "arn:aws:iam::${data.aws_ssm_parameter.test_account_id.value}:role/RepoAdmin",             # test environment (in test account)
        "arn:aws:iam::${data.aws_ssm_parameter.pre_prod_account_id.value}:role/RepoDeveloper",     # pre-prod environment RepoDeveloper (in pre-prod account)
        "arn:aws:iam::${data.aws_ssm_parameter.prod_account_id.value}:role/RepoDeveloper",
        "arn:aws:iam::${data.aws_ssm_parameter.perf_account_id.value}:role/RepoAdmin",
        "arn:aws:iam::${data.aws_ssm_parameter.pre_prod_account_id.value}:role/BootstrapAdmin",     # pre-prod environment RepoDeveloper (in pre-prod account)
        "arn:aws:iam::${data.aws_ssm_parameter.prod_account_id.value}:role/BootstrapAdmin",
        "arn:aws:sts::${data.aws_ssm_parameter.dev_account_id.value}:assumed-role/GitHub-Actions-ReadOnly/GitHubActions",      # dev environment
        "arn:aws:sts::${data.aws_ssm_parameter.test_account_id.value}:assumed-role/GitHub-Actions-ReadOnly/GitHubActions",     # test environment
        "arn:aws:sts::${data.aws_ssm_parameter.pre_prod_account_id.value}:assumed-role/GitHub-Actions-ReadOnly/GitHubActions", # pre-prod environment
        "arn:aws:sts::${data.aws_ssm_parameter.prod_account_id.value}:assumed-role/GitHub-Actions-ReadOnly/GitHubActions",     # prod environment
        # more accounts will follow for other environments...
      ]
    }
  }
}

resource "aws_iam_role" "ci_read_only" {
  name = "CiReadOnly"
  assume_role_policy = data.aws_iam_policy_document.ci_read_only_trust_policy.json
}

resource "aws_iam_role_policy_attachment" "ci_read_only" {
  policy_arn = aws_iam_policy.ci_read_only.arn
  role = aws_iam_role.ci_read_only.name
}

resource "aws_iam_role_policy_attachment" "sms_read_only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
  role = aws_iam_role.ci_read_only.name
}

resource "aws_iam_policy" "ci_read_only" {
  name = "ci-read-only"
  policy = data.aws_iam_policy_document.ci_read_only.json
}

data "aws_iam_policy_document" "ci_read_only" {
  statement {
    effect = "Allow"
    actions = [
      "ecr:DescribeRepositories"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "iam:GetRole",
      "iam:GetPolicy"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
     "ec2:DescribeVpcs",
     "ec2:DescribeRouteTables",
     "ec2:DescribeVpcPeeringConnections"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "route53:GetHostedZone",
      "route53:ListVPCAssociationAuthorizations",
      "route53:ListResourceRecordSets",
      "route53:ListHostedZonesByVPC",
      "route53:ListTagsForResource"
    ]
    resources = ["*"]
  }
}


data "aws_ssm_parameter" "dev_account_id" {
  name = "/repo/dev/user-input/external/aws-account-id"
}

data "aws_ssm_parameter" "test_account_id" {
  name = "/repo/test/user-input/external/aws-account-id"
}

data "aws_ssm_parameter" "pre_prod_account_id" {
  name = "/repo/pre-prod/user-input/external/aws-account-id"
}

data "aws_ssm_parameter" "prod_account_id" {
  name = "/repo/prod/user-input/external/aws-account-id"
}

data "aws_ssm_parameter" "perf_account_id" {
  name = "/repo/perf/user-input/external/aws-account-id"
}