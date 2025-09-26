resource "aws_route53_zone" "environment_public" {
  name = var.deploy_prod_route53_zone ? "${var.environment}.patient-deductions.nhs.uk" : "${var.environment}.non-prod.patient-deductions.nhs.uk"

  tags = {
    CreatedBy = var.repo_name
  }
}

data "aws_ssm_parameter" "non_prod_public_zone" {
  provider = aws.ci
  name     = "/repo/output/prm-deductions-base-infra/non-prod-public-zone-id"
}

data "aws_ssm_parameter" "root_public_zone" {
  provider = aws.ci
  name     = "/repo/output/prm-deductions-base-infra/root-zone-id"
}

resource "aws_route53_record" "environment_ns_prod" {
  count   = var.deploy_prod_route53_zone ? 1 : 0
  name    = "${var.environment}.patient-deductions.nhs.uk"
  ttl     = 30
  type    = "NS"
  zone_id = data.aws_ssm_parameter.root_public_zone.value

  records = aws_route53_zone.environment_public.name_servers
}

resource "aws_route53_record" "environment_ns_non_prod_env" {
  count    = var.deploy_prod_route53_zone ? 0 : 1
  provider = aws.ci
  name     = "${var.environment}.non-prod.patient-deductions.nhs.uk"
  ttl      = 30
  type     = "NS"
  zone_id  = data.aws_ssm_parameter.non_prod_public_zone.value

  records = aws_route53_zone.environment_public.name_servers
}

resource "aws_ssm_parameter" "environment_public_zone_id" {
  name  = "/repo/${var.environment}/output/${var.repo_name}/environment-public-zone-id"
  type  = "String"
  value = aws_route53_zone.environment_public.zone_id

  tags = {
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}