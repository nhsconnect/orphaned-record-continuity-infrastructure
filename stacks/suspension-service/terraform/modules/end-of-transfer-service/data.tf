data "aws_ssm_parameter" "transfer_complete_kms_key" {
  name = "/repo/${var.environment}/output/ehr-transfer-service/transfer-complete-encryption-kms-key"
}
data "aws_ssm_parameter" "transfer_complete_topic_arn" {
  name = "/repo/${var.environment}/output/ehr-transfer-service/transfer-complete-sns-topic-arn"
}