data "aws_caller_identity" "current" {}

data "aws_ssm_parameter" "private_zone_id" {
  name = "/repo/${var.environment}/output/prm-deductions-infra/private-root-zone-id"
}

data "aws_ssm_parameter" "deductions_private_private_subnets" {
  name = "/repo/${var.environment}/output/prm-deductions-infra/deductions-private-private-subnets"
}

data "aws_ssm_parameter" "deductions_private_vpc_id" {
  name = "/repo/${var.environment}/output/prm-deductions-infra/private-vpc-id"
}

data "aws_ssm_parameter" "deductions_private_db_subnets" {
  name = "/repo/${var.environment}/output/prm-deductions-infra/deductions-private-database-subnets"
}

data "aws_ssm_parameter" "jwt_private_key" {
  name = "/repo/${var.environment}/user-input/external/pds-adaptor-jwt-private-key"
}

data "aws_ssm_parameter" "jwt_api_key" {
  name = "/repo/${var.environment}/user-input/external/pds-adaptor-jwt-api-key"
}

data "aws_ssm_parameter" "jwt_key_id" {
  name = "/repo/${var.environment}/user-input/external/pds-adaptor-jwt-key-id"
}

data "aws_ssm_parameter" "access_token_endpoint" {
  name = "/repo/${var.environment}/user-input/external/pds-adaptor-access-token-endpoint"
}

data "aws_ssm_parameter" "pds_fhir_endpoint" {
  name = "/repo/${var.environment}/user-input/external/pds-fhir-endpoint"
}

data "aws_ssm_parameter" "suspension-service-ecs-sg-id" {
  name = "/repo/${var.environment}/output/suspension-service/ecs-sg-id"
}

data "aws_ssm_parameter" "end-for-transfer-service-ecs-sg-id" {
  name = "/repo/${var.environment}/output/end-of-transfer-service/ecs-sg-id"
}

data "aws_ssm_parameter" "re-registration-ecs-sg-id" {
  name = "/repo/${var.environment}/output/re-registration-service/ecs-sg-id"
}