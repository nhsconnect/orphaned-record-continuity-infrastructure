resource "aws_internet_gateway" "internet" {
  vpc_id = aws_vpc.mhs_vpc.id

  tags = {
    Name = "${var.environment}-${var.cluster_name}-mhs-internet-gateway"
    Environment = var.environment
    CreatedBy = var.repo_name
  }
}