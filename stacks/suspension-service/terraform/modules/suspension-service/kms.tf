resource "aws_kms_key" "repo_incoming" {
  description = "Custom KMS Key to enable server side encryption for repo incoming topic"
  policy      = data.aws_iam_policy_document.kms_key_policy_doc.json
  enable_key_rotation = true

  tags = {
    Name        = "${var.environment}-repo-incoming-kms-key"
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}

resource "aws_kms_alias" "repo_incoming_encryption" {
  name          = "alias/${var.component_name}-repo-incoming-encryption-kms-key"
  target_key_id = aws_kms_key.repo_incoming.id
}