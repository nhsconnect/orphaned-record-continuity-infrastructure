data "aws_caller_identity" "current" {}

data "aws_ssm_parameter" "deductions_private_private_subnets" {
  name = "/repo/${var.environment}/output/prm-deductions-infra/deductions-private-private-subnets"
}

data "aws_ssm_parameter" "deductions_private_vpc_id" {
  name = "/repo/${var.environment}/output/prm-deductions-infra/private-vpc-id"
}

data "aws_ssm_parameter" "deductions_core_vpc_id" {
  name = "/repo/${var.environment}/output/prm-deductions-infra/deductions-core-vpc-id"
}

data "aws_ssm_parameter" "gp2gp_messenger_authorization_keys" {
  name = "/repo/${var.environment}/user-input/api-keys/gp2gp-messenger/${var.component_name}"
}

data "aws_ssm_parameter" "ehr_repo_authorization_keys" {
  name = "/repo/${var.environment}/user-input/api-keys/ehr-repo/${var.component_name}"
}

data "aws_ssm_parameter" "private_zone_id" {
  name = "/repo/${var.environment}/output/prm-deductions-infra/private-root-zone-id"
}

data "aws_ssm_parameter" "environment_private_zone_id" {
  name = "/repo/${var.environment}/output/prm-deductions-infra/environment-private-zone-id"
}

data "aws_ssm_parameter" "environment_domain_name" {
  name = "/repo/${var.environment}/output/prm-deductions-infra/environment-domain-name"
}

data "aws_ssm_parameter" "environment_public_zone_id" {
  name = "/repo/${var.environment}/output/prm-deductions-infra/environment-public-zone-id"
}

data "aws_ssm_parameter" "repository_asid" {
  name = "/repo/${var.environment}/user-input/external/repository-asid"
}

data "aws_ssm_parameter" "dynamodb_name" {
  name = "/repo/${var.environment}/output/prm-deductions-infra/ehr-transfer-tracker-db-name"
}

data "aws_ssm_parameter" "deductions_private_db_subnets" {
  name = "/repo/${var.environment}/output/prm-deductions-infra/deductions-private-database-subnets"
}

data "aws_ssm_parameter" "vpn_sg_id" {
  name = "/repo/${var.environment}/output/prm-deductions-infra/vpn-sg-id"
}

data "aws_ssm_parameter" "ehr_in_unhandled_sns_topic_arn" {
  name = "/repo/${var.environment}/output/ehr-transfer-service/ehr-in-unhandled-sns-topic-arn"
}

data "aws_ssm_parameter" "alb_access_logs_bucket" {
  name = "/repo/${var.environment}/output/prm-deductions-infra/alb-access-logs-s3-bucket-id"
}