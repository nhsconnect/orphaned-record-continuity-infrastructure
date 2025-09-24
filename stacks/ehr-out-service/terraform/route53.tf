resource "aws_route53_record" "service" {
  zone_id = data.aws_ssm_parameter.environment_private_zone_id.value
  name    = var.component_name
  type    = "CNAME"
  ttl     = "300"
  records = [aws_alb.alb_internal.dns_name]
}

data "aws_route53_zone" "environment_public_zone" {
  zone_id = data.aws_ssm_parameter.environment_public_zone_id.value
}

resource "aws_acm_certificate" "service_cert" {
  domain_name       = "${var.component_name}.${data.aws_route53_zone.environment_public_zone.name}"
  validation_method = "DNS"

  tags = {
    CreatedBy   = var.repo_name
    Environment = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "service_cert_validation_record" {
  for_each = {
    for dvo in aws_acm_certificate.service_cert.domain_validation_options : dvo.domain_name => {
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

resource "aws_acm_certificate_validation" "service_cert_validation" {
  certificate_arn         = aws_acm_certificate.service_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.service_cert_validation_record : record.fqdn]
}