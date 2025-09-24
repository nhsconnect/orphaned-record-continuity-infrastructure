# Create a private subnet in each availability zone in the region.
resource "aws_subnet" "mhs_subnet" {
  count = 3
  vpc_id = var.mhs_vpc_id
  availability_zone = data.aws_availability_zones.all.names[count.index]

  # Generates a CIDR block with a different prefix within the VPC's CIDR block for each subnet being created.
  # E.g if the VPC's CIDR block is 10.0.0.0/16, this generates subnets that have CIDR blocks 10.0.0.0/24, 10.0.1.0/24,
  # etc.
  # see https://www.terraform.io/docs/configuration/functions/cidrsubnet.html
  cidr_block = var.mhs_subnets[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.environment}-${var.cluster_name}-mhs-private-subnet-${data.aws_availability_zones.all.names[count.index]}"
    Environment = var.environment
    CreatedBy = var.repo_name
  }
}

resource "aws_route_table_association" "mhs" {
  count = 3
  subnet_id      = aws_subnet.mhs_subnet[count.index].id
  route_table_id = aws_route_table.mhs[count.index].id
}