data "aws_iam_policy_document" "strict_env_trust_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_ssm_parameter.nhsd_identities_account_id.value}:root"
      ]
    }
    condition {
      test = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values = [
        "true"
      ]
    }
  }
}

data "aws_caller_identity" "current" {}

data "aws_ssm_parameter" "ci_account_id" {
  name = "/repo/ci/user-input/external/aws-account-id"
}

data "aws_ssm_parameter" "nhsd_identities_account_id" {
  name = "/repo/nhsd-identities/user-input/external/aws-account-id"
}

data "aws_ssm_parameter" "client-vpn-endpoint-id" {
  name = "/repo/${var.environment}/output/prm-deductions-infra/client-vpn-endpoint-id"
}
