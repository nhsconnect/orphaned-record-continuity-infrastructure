resource "aws_nat_gateway" "internet" {
  count = 3
  allocation_id = aws_eip.nat_public_ip[count.index].id
  subnet_id     = aws_subnet.mhs_public_outbound[count.index].id

  tags = {
    Name = "${var.environment}-${var.cluster_name}-mhs-nat-gateway"
    Environment = var.environment
    CreatedBy = var.repo_name
  }
}

resource "aws_eip" "nat_public_ip" {
  count = 3
  tags = {
    Name = "${var.environment}-${var.cluster_name}-mhs-nat-public-ip"
  }
}