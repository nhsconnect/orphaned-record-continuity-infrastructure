resource "aws_cloudwatch_log_group" "vpn" {
  name = "${var.environment}-vpn-client-logs"

  tags = {
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}

resource "aws_cloudwatch_log_stream" "vpn" {
  name           = "main"
  log_group_name = aws_cloudwatch_log_group.vpn.name
}

data "aws_acm_certificate" "vpn" {
  domain   = "${var.environment}.vpn.patient-deductions.nhs.uk"
}

resource "aws_ec2_client_vpn_endpoint" "vpn" {
  server_certificate_arn = data.aws_acm_certificate.vpn.arn
  client_cidr_block      = var.vpn_client_subnet
  split_tunnel           = true
  dns_servers            = [cidrhost(var.cidr, 2)]
  security_group_ids     = [ aws_security_group.vpn.id ]
  vpc_id                 = aws_security_group.vpn.vpc_id

  authentication_options {
    type                       = "certificate-authentication"
    root_certificate_chain_arn = data.aws_acm_certificate.vpn.arn
  }

  connection_log_options {
    enabled               = true
    cloudwatch_log_group  = aws_cloudwatch_log_group.vpn.name
    cloudwatch_log_stream = aws_cloudwatch_log_stream.vpn.name
  }

  tags = {
    Name = "${var.environment}-vpn"
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}

resource "aws_security_group" "vpn" {
    name        = "${var.environment}-vpn-sg"
    description = "Client VPN in ${var.environment} env"
    vpc_id      = module.vpc.vpc_id

    egress {
      description = "Allow private network outbound"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["10.0.0.0/8"]
    }

    tags = {
        Name = "${var.environment}-vpn-sg"
        CreatedBy   = var.repo_name
        Environment = var.environment
    }
}

resource "aws_ssm_parameter" "vpn_sg_id" {
  name = "/repo/${var.environment}/output/${var.repo_name}/vpn-sg-id"
  type = "String"
  value = aws_security_group.vpn.id
}

resource "aws_ec2_client_vpn_network_association" "private_subnet" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn.id
  subnet_id              = module.vpc.private_subnets[0]
}

resource "aws_ec2_client_vpn_authorization_rule" "deductions_private" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn.id
  target_network_cidr    = var.cidr
  authorize_all_groups   = true
}

resource "aws_ec2_client_vpn_route" "gocd_vpc" {
  description = "GoCD vpc"
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn.id
  destination_cidr_block = var.gocd_cidr
  target_vpc_subnet_id   = module.vpc.private_subnets[0]
  depends_on = [aws_ec2_client_vpn_network_association.private_subnet]
}

resource "aws_ec2_client_vpn_authorization_rule" "gocd_vpc" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn.id
  target_network_cidr    = var.gocd_cidr
  authorize_all_groups   = true
}

resource "aws_ec2_client_vpn_route" "repo_mhs_vpc" {
  description = "repo mhs vpc"
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn.id
  destination_cidr_block = var.repo_mhs_vpc_cidr_block
  target_vpc_subnet_id   = module.vpc.private_subnets[0]
  depends_on = [aws_ec2_client_vpn_network_association.private_subnet]
}

resource "aws_ec2_client_vpn_authorization_rule" "repo_mhs_vpc" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn.id
  target_network_cidr    = var.repo_mhs_vpc_cidr_block
  authorize_all_groups   = true
}

resource "aws_ec2_client_vpn_route" "test_harness_mhs_vpc" {
  count = var.test_harness_mhs_vpc_cidr_block != "" ? 1 : 0
  description = "test harness mhs vpc"
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn.id
  destination_cidr_block = var.test_harness_mhs_vpc_cidr_block
  target_vpc_subnet_id   = module.vpc.private_subnets[0]
  depends_on = [aws_ec2_client_vpn_network_association.private_subnet]
}

resource "aws_ec2_client_vpn_authorization_rule" "test_harness_mhs_vpc" {
  count = var.test_harness_mhs_vpc_cidr_block != "" ? 1 : 0
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn.id
  target_network_cidr    = var.test_harness_mhs_vpc_cidr_block
  authorize_all_groups   = true
}

resource "aws_ec2_client_vpn_route" "deductions_core_vpc" {
  description = "deductions core vpc"
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn.id
  destination_cidr_block = var.deductions_core_cidr
  target_vpc_subnet_id   = module.vpc.private_subnets[0]
  depends_on = [aws_ec2_client_vpn_network_association.private_subnet]
}

resource "aws_ec2_client_vpn_authorization_rule" "deductions_core_vpc" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn.id
  target_network_cidr    = var.deductions_core_cidr
  authorize_all_groups   = true
}

resource "aws_ssm_parameter" "client_vpn_endpoint_id" {
  name = "/repo/${var.environment}/output/${var.repo_name}/client-vpn-endpoint-id"
  type = "String"
  value = aws_ec2_client_vpn_endpoint.vpn.id
  tags = {
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}
