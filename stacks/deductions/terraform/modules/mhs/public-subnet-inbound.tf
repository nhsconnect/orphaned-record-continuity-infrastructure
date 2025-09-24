resource "aws_subnet" "mhs_public" {
  count = 3
  vpc_id = aws_vpc.mhs_vpc.id
  availability_zone = data.aws_availability_zones.all.names[count.index]
  cidr_block = var.mhs_public_subnets_inbound[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.environment}-${var.cluster_name}-mhs-public-subnet-inbound-${data.aws_availability_zones.all.names[0]}"
    Environment = var.environment
    CreatedBy = var.repo_name
  }
}

resource "aws_route_table_association" "mhs_public" {
  count = 3
  subnet_id      = aws_subnet.mhs_public[count.index].id
  route_table_id = aws_route_table.public[count.index].id
}