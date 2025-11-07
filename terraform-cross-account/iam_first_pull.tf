data "aws_iam_policy_document" "ecr_pull_first_time" {
  statement {
    sid       = "AuthToken"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid     = "PullCreateImport"
    effect  = "Allow"
    actions = [
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
      "ecr:CreateRepository",
      "ecr:BatchImportUpstreamImage"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ecr_pull_first_time" {
  name   = "ecr-pullthrough-first-pull"
  policy = data.aws_iam_policy_document.ecr_pull_first_time.json
}

# Optional: attach to an existing role by NAME (e.g., ecsTaskExecutionRole or your CI OIDC role)
resource "aws_iam_role_policy_attachment" "attach_role" {
  count      = var.attach_policy_to_role_name == "" ? 0 : 1
  role       = var.attach_policy_to_role_name
  policy_arn = aws_iam_policy.ecr_pull_first_time.arn
}
