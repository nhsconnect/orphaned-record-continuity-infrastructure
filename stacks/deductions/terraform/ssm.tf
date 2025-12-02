resource "aws_ssm_parameter" "ehr_transfer_tracker_db_name" {
  name  = "/repo/${var.environment}/output/prm-deductions-infra/ehr-transfer-tracker-db-name"
  type  = "String"
  value = local.ehr_transfer_tracker_db_name
}