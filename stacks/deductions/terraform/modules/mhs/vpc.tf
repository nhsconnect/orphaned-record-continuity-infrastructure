locals {
  mhs_vpc_id             = aws_vpc.mhs_vpc.id
  mhs_vpc_cidr_block     = aws_vpc.mhs_vpc.cidr_block
  mhs_vpc_route_table_id = aws_vpc.mhs_vpc.main_route_table_id
}

# The MHS VPC that contains the running MHS
resource "aws_vpc" "mhs_vpc" {
  # Note that this cidr block must not overlap with the cidr blocks of the VPCs
  # that the MHS VPC is peered with.
  cidr_block           = var.mhs_vpc_cidr_block
  enable_dns_hostnames = true

  tags = {
    Name        = "${var.environment}-${var.cluster_name}-mhs-vpc"
    Environment = var.environment
    CreatedBy   = var.repo_name
  }
}

// We do not use the default VPC SG. This resource removes all ingress/egress rules from it for security reasons.
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.mhs_vpc.id
}

resource "aws_default_network_acl" "default" {
  default_network_acl_id = aws_vpc.mhs_vpc.default_network_acl_id

  ingress {
    action     = "allow"
    protocol   = "tcp"
    from_port  = 0
    to_port    = 65535
    cidr_block = "0.0.0.0/0"
    rule_no    = 100
  }

  egress {
    action     = "allow"
    protocol   = "tcp"
    from_port  = 0
    to_port    = 65535
    cidr_block = "0.0.0.0/0"
    rule_no    = 100
  }

  lifecycle {
    ignore_changes = [subnet_ids]
  }
}

resource "aws_vpc_ipv4_cidr_block_association" "secondary_cidr" {
  count      = var.mhs_vpc_additional_cidr_block == "" ? 0 : 1
  vpc_id     = aws_vpc.mhs_vpc.id
  cidr_block = var.mhs_vpc_additional_cidr_block
}

resource "aws_flow_log" "nhs_audit" {
  log_destination      = data.aws_ssm_parameter.nhs_audit_flow_s3_bucket_arn.value
  log_destination_type = "s3"
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.mhs_vpc.id

  tags = {
    Name        = "${var.environment}-${var.cluster_name}-mhs-vpc-audit-flow-logs"
    Environment = var.environment
    CreatedBy   = var.repo_name
  }
}

data "aws_ssm_parameter" "nhs_audit_flow_s3_bucket_arn" {
  name = "/repo/user-input/external/nhs-audit-vpc-flow-log-s3-bucket-arn"
}
