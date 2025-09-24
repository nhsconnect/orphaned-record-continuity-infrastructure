resource "aws_route53_zone" "private" {
  name = "patient-deductions.nhs.uk"
  vpc {
    vpc_id = local.deductions_core_vpc_id
  }
  vpc {
    vpc_id = local.deductions_private_vpc_id
  }
}

# Save the zone IDs to use them in other infra projects
resource "aws_ssm_parameter" "private_zone_id" {
  name  = "/repo/${var.environment}/output/${var.repo_name}/private-root-zone-id"
  type  = "String"
  value = aws_route53_zone.private.zone_id

  tags = {
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}

locals {
  environment_domain_name = var.deploy_prod_route53_zone ? "${var.environment}.patient-deductions.nhs.uk" : "${var.environment}.non-prod.patient-deductions.nhs.uk"
}

resource "aws_route53_zone" "environment_private" {
  name = local.environment_domain_name
  # NOTE: The aws_route53_zone vpc argument accepts multiple configuration
  #       blocks. The below usage of the single vpc configuration, the
  #       lifecycle configuration, and the aws_route53_zone_association
  #       resource is to associate with test harness conditionally
  vpc {
    vpc_id = local.deductions_private_vpc_id
  }

  lifecycle {
    ignore_changes = [vpc]
  }
}

resource "aws_ssm_parameter" "environment_private_zone_id" {
  name  = "/repo/${var.environment}/output/${var.repo_name}/environment-private-zone-id"
  type  = "String"
  value = aws_route53_zone.environment_private.zone_id

  tags = {
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}

resource "aws_ssm_parameter" "environment_domain_name" {
  name  = "/repo/${var.environment}/output/${var.repo_name}/environment-domain-name"
  type  = "String"
  value = local.environment_domain_name

  tags = {
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}

resource "aws_route53_zone_association" "core" {
  zone_id = aws_route53_zone.environment_private.zone_id
  vpc_id  = local.deductions_core_vpc_id
}

resource "aws_route53_vpc_association_authorization" "environment_zone_gocd_vpc" {
  count   = var.deploy_cross_account_vpc_peering ? 1 : 0
  vpc_id  = data.aws_ssm_parameter.gocd_vpc.value
  zone_id = aws_route53_zone.environment_private.zone_id
}

resource "aws_route53_zone_association" "gocd" {
  provider = aws.ci
  zone_id  = aws_route53_zone.environment_private.zone_id
  vpc_id   = data.aws_ssm_parameter.gocd_vpc.value
}

resource "aws_route53_zone_association" "repo_mhs" {
  zone_id = aws_route53_zone.environment_private.zone_id
  vpc_id  = local.repo_mhs_vpc_id
}

resource "aws_route53_zone_association" "test_harness_mhs" {
  count   = var.deploy_mhs_test_harness ? 1 : 0
  zone_id = aws_route53_zone.environment_private.zone_id
  vpc_id  = local.test_harness_mhs_vpc_id
}

data "aws_ssm_parameter" "gocd_vpc" {
  provider = aws.ci
  name     = "/repo/prod/output/prm-gocd-infra/gocd-vpc-id"
}