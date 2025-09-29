resource "aws_route_table" "mhs" {
  count = 3
  vpc_id = var.mhs_vpc_id
  tags = {
    Name = "${var.environment}-${var.cluster_name}-mhs-route-table"
    Environment = var.environment
    CreatedBy = var.repo_name
  }
}

resource "aws_route" "internet" {
  count = 3
  route_table_id =   aws_route_table.mhs[count.index].id
  destination_cidr_block =  "0.0.0.0/0"
  nat_gateway_id = var.mhs_nat_gateway_id[count.index]
}

resource "aws_route" "deductions_private" {
  count = 3
  route_table_id            = aws_route_table.mhs[count.index].id
  destination_cidr_block    = var.deductions_private_cidr
  vpc_peering_connection_id = var.deductions_private_vpc_peering_connection_id
}

data "aws_caller_identity" "ci" {
  provider = aws.ci
}

resource "aws_vpc_peering_connection" "mhs_to_gocd" {
  peer_vpc_id = data.aws_ssm_parameter.gocd_vpc.value
  vpc_id = var.mhs_vpc_id
  peer_owner_id = data.aws_caller_identity.ci.account_id
  peer_region = var.region
  auto_accept = var.deploy_cross_account_vpc_peering ? false : true

  tags = {
    Side = "Requester"
    Name = "${var.environment}-mhs-${var.cluster_name}-gocd-peering"
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}

resource "aws_vpc_peering_connection_accepter" "deductions_to_gocd" {
  provider                  = aws.ci
  count = var.deploy_cross_account_vpc_peering ? 1 : 0
  vpc_peering_connection_id = aws_vpc_peering_connection.mhs_to_gocd.id
  auto_accept               = true

  tags = {
    Side = "Accepter"
    Name = "${var.environment}-mhs-${var.cluster_name}-gocd-peering-connection-accepter"
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}

resource "aws_route" "mhs_to_gocd" {
  count = 3
  route_table_id            = aws_route_table.mhs[count.index].id
  destination_cidr_block    = var.gocd_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.mhs_to_gocd.id
}

resource "aws_route" "gocd_to_mhs" {
  provider = aws.ci
  route_table_id            = data.aws_ssm_parameter.gocd_route_table_id.value
  destination_cidr_block    = var.mhs_vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.mhs_to_gocd.id
}

data "aws_ssm_parameter" "gocd_vpc" {
  provider = aws.ci
  name = "/repo/prod/output/prm-gocd-infra/gocd-vpc-id"
}

data "aws_ssm_parameter" "gocd_route_table_id" {
  provider = aws.ci
  name = "/repo/${var.gocd_environment}/output/prm-gocd-infra/gocd-route-table-id"
}