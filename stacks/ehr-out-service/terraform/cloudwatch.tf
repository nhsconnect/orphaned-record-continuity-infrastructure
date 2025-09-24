resource "aws_cloudwatch_log_group" "log_group" {
  name = "/nhs/deductions/${var.environment}-${data.aws_caller_identity.current.account_id}/${var.component_name}"

  tags = {
    Environment = var.environment
    CreatedBy   = var.repo_name
  }
}

data "aws_sns_topic" "alarm_notifications" {
  name = "${var.environment}-alarm-notifications-sns-topic"
}