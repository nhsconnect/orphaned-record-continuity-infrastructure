resource "aws_backup_plan" "cross_account" {
  count = var.s3_backup_enabled ? 1 : 0

  name = "${var.environment}-cross-account"

  rule {
    rule_name         = "CrossAccount7amBackup"
    target_vault_name = aws_backup_vault.s3[0].name
    schedule          = "cron(0 7 * * ? *)"

    copy_action {
      destination_vault_arn = data.aws_ssm_parameter.target_backup_vault_arn[0].value

      lifecycle {
        delete_after       = 35
        cold_storage_after = 0
      }
    }
  }
}

data "aws_ssm_parameter" "target_backup_vault_arn" {
  count = var.s3_backup_enabled ? 1 : 0

  name = "backup-target-vault-arn"
}

resource "aws_iam_policy" "backup_copy" {
  count = var.s3_backup_enabled ? 1 : 0

  name        = "${var.environment}_cross_account_backup_copy"
  description = "Permissions required to copy to another accounts backup vault"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [{
      "Effect" : "Allow",
      "Action" : ["backup:CopyIntoBackupVault"],
      "Resource" : data.aws_ssm_parameter.target_backup_vault_arn[0].value
    }]
  })
}

resource "aws_iam_role_policy_attachment" "cross_account_backup_copy" {
  count = var.s3_backup_enabled ? 1 : 0

  role       = aws_iam_role.cross_account_backup[0].name
  policy_arn = aws_iam_policy.backup_copy[0].arn
}

resource "aws_backup_selection" "cross_account" {
  count = var.s3_backup_enabled ? 1 : 0

  iam_role_arn = aws_iam_role.cross_account_backup[0].arn
  name         = "${var.environment}_cross_account"
  plan_id      = aws_backup_plan.cross_account[0].id

  resources = [
    aws_s3_bucket.alb_access_logs.arn,
    data.aws_s3_bucket.ehr_repo_bucket.arn,
    data.aws_s3_bucket.ehr_repo_access_logs.arn,
    data.aws_dynamodb_table.ehr_transfer_service_transfer_tracker.arn,
    data.aws_dynamodb_table.end_of_transfer_service_dynamodb.arn,
    data.aws_dynamodb_table.re_registration_service_active_suspensions.arn,
    data.aws_dynamodb_table.repo_mhs_state.arn,
    data.aws_dynamodb_table.repo_mhs_sync_async_state.arn,
    data.aws_dynamodb_table.suspension_service_dynamodb.arn,
    data.aws_dynamodb_table.prm_deductions_terraform_table.arn,
    module.ehr_transfer_tracker_dynamodb_table.dynamodb_table_arn,
    aws_s3_bucket.access_logs.arn,
    data.aws_s3_bucket.terraform_state.arn,
    data.aws_s3_bucket.terraform_state_store.arn
  ]
}

resource "aws_iam_role" "cross_account_backup" {
  count = var.s3_backup_enabled ? 1 : 0

  name = "${var.environment}_cross_account_backup"

  assume_role_policy = data.aws_iam_policy_document.backup_assume_role[0].json
}

resource "aws_iam_role_policy_attachment" "cross_account_backup" {
  count = var.s3_backup_enabled ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
  role       = aws_iam_role.cross_account_backup[0].name
  depends_on = [aws_iam_role.cross_account_backup]
}

resource "aws_iam_role_policy_attachment" "cross_account_restore" {
  count = var.s3_backup_enabled ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
  role       = aws_iam_role.cross_account_backup[0].name
  depends_on = [aws_iam_role.cross_account_backup]
}

resource "aws_iam_role_policy_attachment" "cross_account_s3_backup" {
  count = var.s3_backup_enabled ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/AWSBackupServiceRolePolicyForS3Backup"
  role       = aws_iam_role.cross_account_backup[0].name
  depends_on = [aws_iam_role.cross_account_backup]
}

resource "aws_iam_role_policy_attachment" "s3_cross_account_restore" {
  count = var.s3_backup_enabled ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/AWSBackupServiceRolePolicyForS3Restore"
  role       = aws_iam_role.cross_account_backup[0].name
  depends_on = [aws_iam_role.cross_account_backup]
}
