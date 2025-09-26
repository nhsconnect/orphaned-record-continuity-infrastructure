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