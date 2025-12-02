resource "aws_backup_vault" "s3" {
  count = var.s3_backup_enabled ? 1 : 0

  name = "${var.environment}_s3"
}

resource "aws_backup_plan" "s3_continuous" {
  count = var.s3_backup_enabled ? 1 : 0

  name = "${var.environment}_s3_continuous"

  rule {
    enable_continuous_backup = true
    rule_name                = "S3BucketContinousBackups"
    target_vault_name        = aws_backup_vault.s3[0].name
    recovery_point_tags      = {}
    schedule                 = "cron(0 5 ? * * *)"

    lifecycle {
      cold_storage_after                        = 0
      delete_after                              = 35
      opt_in_to_archive_for_supported_resources = false
    }
  }
}

resource "aws_backup_selection" "s3_continuous" {
  count = var.s3_backup_enabled ? 1 : 0

  iam_role_arn = aws_iam_role.s3_backup[0].arn
  name         = "${var.environment}_s3_continuous"
  plan_id      = aws_backup_plan.s3_continuous[0].id

  resources = [
    aws_s3_bucket.alb_access_logs.arn,
    data.aws_s3_bucket.ehr_repo_bucket.arn,
    data.aws_s3_bucket.ehr_repo_access_logs.arn,
    aws_s3_bucket.access_logs.arn,
    data.aws_s3_bucket.terraform_state.arn,
    data.aws_s3_bucket.terraform_state_store.arn
  ]
}

data "aws_iam_policy_document" "backup_assume_role" {
  count = var.s3_backup_enabled ? 1 : 0

  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "s3_backup" {
  count = var.s3_backup_enabled ? 1 : 0

  name               = "${var.environment}_s3_backup"
  assume_role_policy = data.aws_iam_policy_document.backup_assume_role[0].json
}

resource "aws_iam_role_policy_attachment" "backup_policy" {
  count = var.s3_backup_enabled ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
  role       = aws_iam_role.s3_backup[0].name
  depends_on = [aws_iam_role.s3_backup]
}

resource "aws_iam_role_policy_attachment" "restore_policy" {
  count = var.s3_backup_enabled ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
  role       = aws_iam_role.s3_backup[0].name
  depends_on = [aws_iam_role.s3_backup]
}

resource "aws_iam_role_policy_attachment" "s3_backup_policy" {
  count = var.s3_backup_enabled ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/AWSBackupServiceRolePolicyForS3Backup"
  role       = aws_iam_role.s3_backup[0].name
  depends_on = [aws_iam_role.s3_backup]
}

resource "aws_iam_role_policy_attachment" "s3_restore_policy" {
  count = var.s3_backup_enabled ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/AWSBackupServiceRolePolicyForS3Restore"
  role       = aws_iam_role.s3_backup[0].name
  depends_on = [aws_iam_role.s3_backup]
}