module "vpc" {
  source                        = "terraform-aws-modules/vpc/aws"
  version                       = "5.5.2"
  name                          = "${var.environment}-${var.component_name}-vpc"
  cidr                          = var.cidr
  azs                           = var.azs
  private_subnets               = var.private_subnets
  database_subnets              = var.database_subnets
  map_public_ip_on_launch       = true
  enable_vpn_gateway            = false
  enable_dns_support            = true
  enable_dns_hostnames          = true
  manage_default_security_group = false
  manage_default_route_table    = false
  manage_default_network_acl    = false

  tags = {
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}

// We do not use the default VPC SG. This resource removes all ingress/egress rules from it for security reasons.
resource "aws_default_security_group" "default" {
  depends_on = [module.vpc]
  vpc_id     = module.vpc.vpc_id
}

resource "aws_default_network_acl" "default" {
  default_network_acl_id = module.vpc.default_network_acl_id

  ingress {
    action     = "allow"
    protocol   = "tcp"
    from_port  = 443
    to_port    = 443
    cidr_block = "0.0.0.0/0"
    rule_no    = 100
  }

  ingress {
    action     = "allow"
    protocol   = "tcp"
    from_port  = 1024
    to_port    = 65535
    cidr_block = "0.0.0.0/0"
    rule_no    = 101
  }

  egress {
    action     = "allow"
    protocol   = "tcp"
    from_port  = 443
    to_port    = 443
    cidr_block = "0.0.0.0/0"
    rule_no    = 100
  }

  egress {
    action     = "allow"
    protocol   = "tcp"
    from_port  = 1024
    to_port    = 65535
    cidr_block = "0.0.0.0/0"
    rule_no    = 101
  }

  lifecycle {
    ignore_changes = [subnet_ids]
  }
}

resource "aws_route" "core_to_private" {
  count                     = length(module.vpc.private_route_table_ids)
  route_table_id            = module.vpc.private_route_table_ids[count.index]
  destination_cidr_block    = var.deductions_private_cidr
  vpc_peering_connection_id = var.core_private_vpc_peering_connection_id
}

data "aws_caller_identity" "ci" {
  provider = aws.ci
}

resource "aws_flow_log" "nhs_audit" {
  log_destination      = data.aws_ssm_parameter.nhs_audit_flow_s3_bucket_arn.value
  log_destination_type = "s3"
  traffic_type         = "ALL"
  vpc_id               = module.vpc.vpc_id

  tags = {
    Name        = "${var.environment}-deductions-core-vpc-audit-flow-logs"
    Environment = var.environment
    CreatedBy   = var.repo_name
  }
}

data "aws_ssm_parameter" "nhs_audit_flow_s3_bucket_arn" {
  name = "/repo/user-input/external/nhs-audit-vpc-flow-log-s3-bucket-arn"
}
