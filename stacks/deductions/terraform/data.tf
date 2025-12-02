data "aws_caller_identity" "current" {}

data "aws_ssm_parameter" "sender_cost_report_email_id" {
  name = "/repo/${var.environment}/user-input/sender-cost-report-email-id"
}

data "aws_ssm_parameter" "receiver_cost_report_email_id" {
  name = "/repo/${var.environment}/user-input/receiver-cost-report-email-id"
}

data "aws_ssm_parameter" "support_cost_report_email_id" {
  name = "/repo/${var.environment}/user-input/support-cost-report-email-id"
}

data "aws_s3_bucket" "ehr_repo_bucket" {
  bucket = "${var.environment}-ehr-repo-bucket"
}

data "aws_s3_bucket" "ehr_repo_access_logs" {
  bucket = "${var.environment}-ehr-repo-access-logs"
}

data "aws_s3_bucket" "terraform_state" {
  bucket = "prm-deductions-${var.environment}-terraform-state"
}

data "aws_s3_bucket" "terraform_state_store" {
  bucket = "prm-deductions-${var.environment}-terraform-state-store"
}

data "aws_dynamodb_table" "ehr_transfer_service_transfer_tracker" {
  name = "${var.environment}-ehr-transfer-service-transfer-tracker"
}

data "aws_dynamodb_table" "end_of_transfer_service_dynamodb" {
  name = "${var.environment}-end-of-transfer-service-dynamodb"
}

data "aws_dynamodb_table" "re_registration_service_active_suspensions" {
  name = "${var.environment}-re-registration-service-active-suspensions"
}

data "aws_dynamodb_table" "repo_mhs_state" {
  name = "${var.environment}-repo-mhs-state"
}

data "aws_dynamodb_table" "repo_mhs_sync_async_state" {
  name = "${var.environment}-repo-mhs-sync-async-state"
}

data "aws_dynamodb_table" "suspension_service_dynamodb" {
  name = "${var.environment}-suspension-service-dynamodb"
}

data "aws_dynamodb_table" "prm_deductions_terraform_table" {
  name = "prm-deductions-${var.environment}-terraform-table"
}
