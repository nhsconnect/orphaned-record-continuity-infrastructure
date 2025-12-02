data "aws_caller_identity" "current" {}

data "aws_sns_topic" "alarm_notifications" {
  name = "${var.environment}-alarm-notifications-sns-topic"
}

data "aws_ssm_parameter" "deductions_private_vpc_id" {
  name = "/repo/${var.environment}/output/prm-deductions-infra/private-vpc-id"
}

data "aws_ssm_parameter" "deductions_private_private_subnets" {
  name = "/repo/${var.environment}/output/prm-deductions-infra/deductions-private-private-subnets"
}

data "aws_ssm_parameter" "re_registrations_kms_key_id" {
  name = "/repo/${var.environment}/output/prm-deductions-nems-event-processor/re-registrations-kms-key-id"
}

data "aws_ssm_parameter" "re_registrations_sns_topic_arn" {
  name = "/repo/${var.environment}/output/nems-event-processor/re-registrations-sns-topic-arn"
}

data "aws_ssm_parameter" "environment_domain_name" {
  name = "/repo/${var.environment}/output/prm-deductions-infra/environment-domain-name"
}

data "aws_ssm_parameter" "pds_adaptor_auth_password" {
  name = "/repo/${var.environment}/user-input/api-keys/pds-adaptor/re-registration-service"
}

data "aws_ssm_parameter" "re_registration_service_authorization_keys_for_ehr_repo" {
  name = "/repo/${var.environment}/user-input/api-keys/ehr-repo/re-registration-service"
}

data "aws_ssm_parameter" "service-to-ehr-repo-sg-id" {
  name = "/repo/${var.environment}/output/prm-deductions-ehr-repository/service-to-ehr-repo-sg-id"
}

data "aws_vpc" "deductions-private" {
  id = data.aws_ssm_parameter.deductions_private_vpc_id.value
}

data "aws_vpc" "deductions-core" {
  id = data.aws_ssm_parameter.deductions_core_vpc_id.value
}

data "aws_ssm_parameter" "deductions_core_vpc_id" {
  name = "/repo/${var.environment}/output/prm-deductions-infra/deductions-core-vpc-id"
}

data "aws_ssm_parameter" "active_suspensions_kms_key_id" {
  name = "/repo/${var.environment}/output/suspension-service/active-suspensions-kms-key-id"
}

data "aws_ssm_parameter" "suspension_active_suspensions_topic_arn" {
  name = "/repo/${var.environment}/output/suspension-service/active-suspensions-topic-arn"
}

data "aws_ssm_parameter" "end_of_transfer_active_suspensions_topic_arn" {
  name = "/repo/${var.environment}/output/end-of-transfer-service/active-suspensions-topic-arn"
}