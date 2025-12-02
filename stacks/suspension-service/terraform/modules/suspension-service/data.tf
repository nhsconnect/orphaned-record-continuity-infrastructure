data "aws_caller_identity" "current" {}

data "aws_ssm_parameter" "suspensions_sns_topic_arn" {
  name = "/repo/${var.environment}/output/nems-event-processor/suspensions-sns-topic-arn"
}

data "aws_ssm_parameter" "suspensions_kms_key_id" {
  name = "/repo/${var.environment}/output/prm-deductions-nems-event-processor/suspensions-kms-key-id"
}

data "aws_s3_bucket" "access_logs" {
  bucket = "${var.environment}-orc-access-logs"
}
