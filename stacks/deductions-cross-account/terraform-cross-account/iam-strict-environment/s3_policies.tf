resource "aws_iam_policy" "s3_allow_terraform_state_content_access" {
  name = "s3_allow_terraform_state_content_access"
  policy = data.aws_iam_policy_document.s3_allow_terraform_state_content_access.json
}

resource "aws_iam_policy" "s3_allow_ehr_repo_content_access" {
  name = "s3_allow_ehr_repo_content_access"
  policy = data.aws_iam_policy_document.s3_allow_ehr_repo_content_access.json
}

resource "aws_iam_policy" "s3_allow_ehr_repo_log_bucket_access" {
  name = "s3_allow_ehr_repo_log_bucket_access"
  policy = data.aws_iam_policy_document.s3_allow_ehr_repo_log.json
}

resource "aws_iam_policy" "s3_allow_list_buckets" {
  name = "s3_allow_list_buckets"
  policy = data.aws_iam_policy_document.s3_allow_list_buckets.json
}


data "aws_iam_policy_document" "s3_allow_list_buckets" {
  statement {
    sid = "S3AllowListBuckets"
    effect = "Allow"
    actions = [
      "s3:ListAllMyBuckets"
    ]
    resources = [
      "*"
    ]
  }
}

data "aws_iam_policy_document" "s3_allow_terraform_state_content_access" {
  statement {
    sid = "S3AllowTerraformStateContentAccess"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:List*",
      "s3:GetBucket*",
      "s3:GetLifecycleConfiguration",
      "s3:GetEncryptionConfiguration"
    ]
    resources = [
      "arn:aws:s3:::prm-deductions-${var.state_bucket_infix}terraform-state*",
      "arn:aws:s3:::prm-deductions-${var.state_bucket_infix}terraform-state/*",
      "arn:aws:s3:::prm-deductions-${var.state_bucket_infix}terraform-state-store/*",
      "arn:aws:s3:::prm-deductions-${var.state_bucket_infix}terraform-state-store*"
    ]
  }
}

data "aws_iam_policy_document" "s3_allow_ehr_repo_content_access" {
  statement {
    sid = "S3AllowEhrRepoBucketReadAccess"
    effect = "Allow"
    actions = [
        "s3:List*",
        "s3:Get*"
    ]
    resources = ["arn:aws:s3:::${var.environment}-ehr-repo-bucket"]
  }
}

data "aws_iam_policy_document" "s3_allow_ehr_repo_log" {
  statement {
    sid = "S3AllowEhrRepoLogBucketReadAccess"
    effect = "Allow"
    actions = [
      "s3:List*",
      "s3:Get*"
    ]
    resources = ["arn:aws:s3:::${var.environment}-ehr-repo-log-bucket", "arn:aws:s3:::${var.environment}-ehr-repo-log-bucket/*"]
  }
}