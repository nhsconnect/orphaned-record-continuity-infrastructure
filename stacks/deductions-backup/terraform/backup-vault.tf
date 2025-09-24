resource "aws_backup_vault" "this" {
  name        = "${var.environment}-backup-vault"
  kms_key_arn = aws_kms_key.vault.arn
}

resource "aws_kms_key" "vault" {
  description         = "KMS key for encrypting backups"
  enable_key_rotation = true
}

resource "aws_kms_alias" "vault" {
  target_key_id = aws_kms_key.vault.id
}

resource "aws_backup_vault_policy" "cross_account" {
  backup_vault_name = aws_backup_vault.this.name

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "Allow ${data.aws_ssm_parameter.backup_source_account.value} to copy into ${aws_backup_vault.this.name}",
          "Effect" : "Allow",
          "Principal" : {
            "AWS" : "arn:aws:iam::${data.aws_ssm_parameter.backup_source_account.value}:root"
          },
          "Action" : "backup:CopyIntoBackupVault",
          "Resource" : "*"
        }
      ]
    }
  )
}

data "aws_ssm_parameter" "backup_source_account" {
  name = "backup-source-account"
}
