module "vpc" {
  source                        = "terraform-aws-modules/vpc/aws"
  version                       = "5.5.2"
  name                          = "${var.environment}-${var.component_name}-vpc"
  cidr                          = var.cidr
  azs                           = var.azs
  private_subnets               = var.private_subnets
  public_subnets                = var.public_subnets
  database_subnets              = var.database_subnets
  enable_vpn_gateway            = false
  map_public_ip_on_launch       = true
  enable_nat_gateway            = true
  single_nat_gateway            = true
  one_nat_gateway_per_az        = false
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

  ingress {
    action     = "allow"
    protocol   = "tcp"
    from_port  = 22
    to_port    = 22
    cidr_block = "0.0.0.0/0"
    rule_no    = 102
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

  egress {
    action     = "allow"
    protocol   = "tcp"
    from_port  = 22
    to_port    = 22
    cidr_block = "0.0.0.0/0"
    rule_no    = 102
  }

  lifecycle {
    ignore_changes = [subnet_ids]
  }
}

resource "aws_route" "private_private_to_core" {
  route_table_id            = module.vpc.private_route_table_ids[0]
  destination_cidr_block    = var.deductions_core_cidr
  vpc_peering_connection_id = var.core_private_vpc_peering_connection_id
}

resource "aws_route" "private_public_to_core" {
  route_table_id            = module.vpc.public_route_table_ids[0]
  destination_cidr_block    = var.deductions_core_cidr
  vpc_peering_connection_id = var.core_private_vpc_peering_connection_id
}

resource "aws_route" "private_private_to_mhs_repo" {
  route_table_id            = module.vpc.private_route_table_ids[0]
  destination_cidr_block    = var.repo_mhs_vpc_cidr_block
  vpc_peering_connection_id = var.repo_mhs_vpc_peering_connection_id
}

resource "aws_route" "private_private_to_mhs_test_harness" {
  count                     = var.deploy_mhs_test_harness ? 1 : 0
  route_table_id            = module.vpc.private_route_table_ids[0]
  destination_cidr_block    = var.test_harness_mhs_vpc_cidr_block
  vpc_peering_connection_id = var.test_harness_mhs_vpc_peering_connection_id
}

resource "aws_route" "private_public_to_mhs_repo" {
  route_table_id            = module.vpc.public_route_table_ids[0]
  destination_cidr_block    = var.repo_mhs_vpc_cidr_block
  vpc_peering_connection_id = var.repo_mhs_vpc_peering_connection_id
}

resource "aws_route" "private_public_to_mhs_test_harness" {
  count                     = var.deploy_mhs_test_harness ? 1 : 0
  route_table_id            = module.vpc.public_route_table_ids[0]
  destination_cidr_block    = var.test_harness_mhs_vpc_cidr_block
  vpc_peering_connection_id = var.test_harness_mhs_vpc_peering_connection_id
}

data "aws_caller_identity" "ci" {
  provider = aws.ci
}

resource "aws_vpc_peering_connection" "private_to_gocd" {
  peer_vpc_id   = data.aws_ssm_parameter.gocd_vpc.value
  vpc_id        = module.vpc.vpc_id
  peer_owner_id = data.aws_caller_identity.ci.account_id
  peer_region   = var.region
  auto_accept   = var.deploy_cross_account_vpc_peering ? false : true

  tags = {
    Side        = "Requester"
    Name        = "${var.environment}-deductions-private-gocd-peering"
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}

resource "aws_vpc_peering_connection_accepter" "private_to_gocd" {
  provider                  = aws.ci
  count                     = var.deploy_cross_account_vpc_peering ? 1 : 0
  vpc_peering_connection_id = aws_vpc_peering_connection.private_to_gocd.id
  auto_accept               = true

  tags = {
    Side        = "Accepter"
    Name        = "${var.environment}-deductions-private-to-gocd-peering-connection-accepter"
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}

resource "aws_route" "private_private_to_gocd" {
  route_table_id            = module.vpc.private_route_table_ids[0]
  destination_cidr_block    = var.gocd_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.private_to_gocd.id
}

resource "aws_route" "private_public_to_gocd" {
  route_table_id            = module.vpc.public_route_table_ids[0]
  destination_cidr_block    = var.gocd_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.private_to_gocd.id
}

resource "aws_route" "gocd_to_private" {
  provider                  = aws.ci
  route_table_id            = data.aws_ssm_parameter.gocd_route_table_id.value
  destination_cidr_block    = var.cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.private_to_gocd.id
}

# Allow DNS resolution of the domain names defined in gocd VPC in deductions_private vpc
resource "aws_route53_zone_association" "deductions_private_hosted_zone_gocd_vpc_association" {
  zone_id = data.aws_ssm_parameter.gocd_zone_id.value
  vpc_id  = module.vpc.vpc_id
}

resource "aws_route53_vpc_association_authorization" "deductions_private_hosted_zone_gocd_vpc" {
  count    = var.deploy_cross_account_vpc_peering ? 1 : 0
  provider = aws.ci
  vpc_id   = module.vpc.vpc_id
  zone_id  = data.aws_ssm_parameter.gocd_zone_id.value
}

resource "aws_flow_log" "nhs_audit" {
  log_destination      = data.aws_ssm_parameter.nhs_audit_flow_s3_bucket_arn.value
  log_destination_type = "s3"
  traffic_type         = "ALL"
  vpc_id               = module.vpc.vpc_id

  tags = {
    Name        = "${var.environment}-deductions-private-vpc-audit-flow-logs"
    Environment = var.environment
    CreatedBy   = var.repo_name
  }
}

data "aws_ssm_parameter" "gocd_vpc" {
  provider = aws.ci
  name     = "/repo/prod/output/prm-gocd-infra/gocd-vpc-id"
}

data "aws_ssm_parameter" "gocd_route_table_id" {
  provider = aws.ci
  name     = "/repo/${var.gocd_environment}/output/prm-gocd-infra/gocd-route-table-id"
}

data "aws_ssm_parameter" "gocd_zone_id" {
  provider = aws.ci
  name     = "/repo/${var.gocd_environment}/output/prm-gocd-infra/gocd-route53-zone-id"
}

data "aws_ssm_parameter" "nhs_audit_flow_s3_bucket_arn" {
  name = "/repo/user-input/external/nhs-audit-vpc-flow-log-s3-bucket-arn"
}
