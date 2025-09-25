data "aws_iam_policy_document" "repo_admin_trust_policy" {
  count = var.provision_strict_iam_roles ? 0 : 1
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

resource "aws_iam_role" "repo_admin" {
  count = var.provision_strict_iam_roles ? 0 : 1
  name = "RepoAdmin"
  assume_role_policy = data.aws_iam_policy_document.repo_admin_trust_policy[0].json
}


resource "aws_iam_role_policy_attachment" "repo_admin" {
  count = var.provision_strict_iam_roles ? 0 : 1
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
  role = aws_iam_role.repo_admin[0].name
}

data "aws_ssm_parameter" "ci_account_id" {
  name = "/repo/ci/user-input/external/aws-account-id"
}

data "aws_ssm_parameter" "nhsd_identities_account_id" {
  name = "/repo/nhsd-identities/user-input/external/aws-account-id"
}