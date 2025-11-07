output "ecr_pullthrough_rules" {
  value = {
    mhs_in  = aws_ecr_pull_through_cache_rule.mhs_in.arn
    mhs_out = aws_ecr_pull_through_cache_rule.mhs_out.arn
  }
}

output "ecr_image_urls" {
  value = {
    inbound  = "${data.aws_caller_identity.this.account_id}.dkr.ecr.${var.region}.amazonaws.com/mhs-in/nhsdev/nia-mhs-inbound:latest"
    outbound = "${data.aws_caller_identity.this.account_id}.dkr.ecr.${var.region}.amazonaws.com/mhs-out/nhsdev/nia-mhs-outbound:latest"
  }
}

output "vpc_endpoints" {
  value = {
    ecr_api = aws_vpc_endpoint.ecr_api.id
    ecr_dkr = aws_vpc_endpoint.ecr_dkr.id
    s3      = aws_vpc_endpoint.s3.id
  }
}
