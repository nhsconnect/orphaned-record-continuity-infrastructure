data "aws_ssm_parameter" "environment_private_zone_id" {
  name = "/repo/${var.environment}/output/prm-deductions-infra/environment-private-zone-id"
}

data "aws_ssm_parameter" "environment_domain_name" {
  name = "/repo/${var.environment}/output/prm-deductions-infra/environment-domain-name"
}

data "aws_ssm_parameter" "environment_public_zone_id" {
  name = "/repo/${var.environment}/output/prm-deductions-infra/environment-public-zone-id"
}

data "aws_route53_zone" "environment_public_zone" {
  zone_id = data.aws_ssm_parameter.environment_public_zone_id.value
}

resource "aws_route53_record" "pds_adaptor" {
  zone_id = data.aws_ssm_parameter.environment_private_zone_id.value
  name    = var.dns_name
  type    = "CNAME"
  ttl     = "300"
  records = [aws_alb.alb-internal.dns_name]
}

moved {
  from = aws_acm_certificate.pds-adaptor-cert
  to   = aws_acm_certificate.pds_adaptor_cert
}

resource "aws_acm_certificate" "pds_adaptor_cert" {
  domain_name = "${var.dns_name}.${data.aws_route53_zone.environment_public_zone.name}"

  validation_method = "DNS"

  tags = {
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}

resource "aws_route53_record" "pds_adaptor_cert_validation_record" {
  for_each = {
    for dvo in aws_acm_certificate.pds_adaptor_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.environment_public_zone.zone_id
}

resource "aws_acm_certificate_validation" "pds_adaptor_cert_validation" {
  certificate_arn         = aws_acm_certificate.pds_adaptor_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.pds_adaptor_cert_validation_record : record.fqdn]
}
