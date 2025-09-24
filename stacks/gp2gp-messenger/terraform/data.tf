data "aws_caller_identity" "current" {}

data "aws_ssm_parameter" "private_zone_id" {
  name = "/repo/${var.environment}/output/prm-deductions-infra/private-root-zone-id"
}

data "aws_ssm_parameter" "GP2GP_MESSENGER_REPOSITORY_ODS_CODE" {
  name = "/repo/${var.environment}/user-input/external/repository-ods-code"
}

data "aws_ssm_parameter" "GP2GP_MESSENGER_REPOSITORY_ASID" {
  name = "/repo/${var.environment}/user-input/external/repository-asid"
}

data "aws_ssm_parameter" "deductions_private_private_subnets" {
  name = "/repo/${var.environment}/output/prm-deductions-infra/deductions-private-private-subnets"
}

data "aws_ssm_parameter" "deductions_private_vpc_id" {
  name = "/repo/${var.environment}/output/prm-deductions-infra/private-vpc-id"
}

data "aws_ssm_parameter" "GP2GP_MESSENGER_MHS_OUTBOUND_URL" {
  name = "/repo/${var.environment}/output/prm-mhs-infra/repo-mhs-outbound-url"
}

data "aws_ssm_parameter" "nhs_number_prefix" {
  name = "/repo/${var.environment}/user-input/nhs-number-prefix"
}

data "aws_ssm_parameter" "sds_fhir_api_key" {
  name = "/repo/${var.environment}/user-input/external/sds-fhir-api-key"
}

data "aws_ssm_parameter" "sds_fhir_url" {
  name = "/repo/${var.environment}/user-input/external/sds-fhir-url"
}

data "aws_ssm_parameter" "safe_listed_ods_codes" {
  name = "/repo/${var.environment}/user-input/external/safe-listed-ods-codes"
}
