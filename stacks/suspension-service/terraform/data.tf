data "aws_caller_identity" "current" {}

data "aws_ssm_parameter" "environment_domain_name" {
  name = "/repo/${var.environment}/output/prm-deductions-infra/environment-domain-name"
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

data "aws_ssm_parameter" "pds_adaptor_auth_key" {
  name = "/repo/${var.environment}/user-input/api-keys/pds-adaptor/suspension-service"
}

data "aws_ssm_parameter" "repo_ods_code" {
  name = "/repo/${var.environment}/user-input/external/repository-ods-code"
}

data "aws_ssm_parameter" "safe_listed_ods_codes" {
  name = "/repo/${var.environment}/user-input/external/safe-listed-ods-codes"
}
