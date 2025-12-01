resource "aws_route53_zone" "public" {
  name = "patient-deductions.nhs.uk"

  tags = {
    CreatedBy = var.repo_name
  }
}

// Even though the zone is created in prod account, we save its ID in ci account
// so that we can leverage the multi provider terraform setup in deductions-infra
resource "aws_ssm_parameter" "public_zone_id" {
  name = "/repo/output/output/prm-deductions-infra/root-zone-id"
  type  = "String"
  value = aws_route53_zone.public.zone_id

  tags = {
    CreatedBy = var.repo_name
  }
}

resource "aws_route53_zone" "non_prod_public" {
  provider = aws.ci
  name = "non-prod.patient-deductions.nhs.uk"

  tags = {
    CreatedBy = var.repo_name
  }
}

// This should be removed once NHS points to the root zone in production
resource "aws_route53_record" "non_prod_ns_ci" {
  provider = aws.ci
  name = "non-prod.patient-deductions.nhs.uk"
  ttl = 30
  type = "NS"
  zone_id = var.root_dns_zone_id_in_ci

  records = aws_route53_zone.non_prod_public.name_servers
}

resource "aws_route53_record" "non_prod_ns" {
  name = "non-prod.patient-deductions.nhs.uk"
  ttl = 30
  type = "NS"
  zone_id = aws_route53_zone.public.zone_id

  records = aws_route53_zone.non_prod_public.name_servers
}

resource "aws_ssm_parameter" "non_prod_public_zone_id" {
  name = "/repo/output/output/prm-deductions-infra/non-prod-public-zone-id"
  type  = "String"
  value = aws_route53_zone.non_prod_public.zone_id

  tags = {
    CreatedBy = var.repo_name
  }
}
