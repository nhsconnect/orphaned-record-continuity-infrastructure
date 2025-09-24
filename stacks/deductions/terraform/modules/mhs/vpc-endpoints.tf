locals {
  subnet_ids = module.cluster.subnet_ids
}

# ECR VPC docker API endpoint
resource "aws_vpc_endpoint" "ecr_endpoint" {
  vpc_id = aws_vpc.mhs_vpc.id
  service_name = "com.amazonaws.${var.region}.ecr.dkr"
  vpc_endpoint_type = "Interface"
  private_dns_enabled = true

  security_group_ids = [
    aws_security_group.ecr_security_group.id
  ]

  # An endpoint network interface is created in all of the subnets we have created.
  subnet_ids = local.subnet_ids

  tags = {
    Name = "${var.environment}-${var.cluster_name}-ecr-docker-endpoint"
    Environment = var.environment
    CreatedBy = var.repo_name
  }
}

resource "aws_security_group" "ecr_security_group" {
  name = "${var.environment}-${var.cluster_name}-mhs-ecr-endpoint"
  description = "The security group used to control traffic for the ECR VPC endpoint."
  vpc_id = aws_vpc.mhs_vpc.id

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = [ var.mhs_vpc_cidr_block ]
    description = "Allow inbound HTTPS requests from MHS VPC"
  }

  tags = {
    Name = "${var.environment}-${var.cluster_name}-mhs-ecr-endpoint"
    Environment = var.environment
    CreatedBy = var.repo_name
  }
}

# ECR VPC API endpoint - needed for docker login
resource "aws_vpc_endpoint" "ecr_api_endpoint" {
  vpc_id = aws_vpc.mhs_vpc.id
  service_name = "com.amazonaws.${var.region}.ecr.api"
  vpc_endpoint_type = "Interface"
  private_dns_enabled = true

  security_group_ids = [
    aws_security_group.ecr_security_group.id
  ]

  # An endpoint network interface is created in all of the subnets we have created.
  subnet_ids = local.subnet_ids

  tags = {
    Name = "${var.environment}-${var.cluster_name}-ecr-api-endpoint"
    Environment = var.environment
    CreatedBy = var.repo_name
  }
}

# Cloudwatch VPC endpoint
resource "aws_vpc_endpoint" "cloudwatch_endpoint" {
  vpc_id = aws_vpc.mhs_vpc.id
  service_name = "com.amazonaws.${var.region}.logs"
  vpc_endpoint_type = "Interface"
  private_dns_enabled = true

  security_group_ids = [
    aws_security_group.cloudwatch_security_group.id
  ]

  # An endpoint network interface is created in all of the subnets we have created.
  subnet_ids = local.subnet_ids

  tags = {
    Name = "${var.environment}-${var.cluster_name}-cloudwatch-endpoint"
    Environment = var.environment
    CreatedBy = var.repo_name
  }
}

# Security group for the Cloudwatch VPC endpoint
resource "aws_security_group" "cloudwatch_security_group" {
  name = "${var.environment}-${var.cluster_name}-mhs-cloudwatch"
  description = "The security group used to control traffic for the Cloudwatch VPC endpoint."
  vpc_id = aws_vpc.mhs_vpc.id

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = [ var.mhs_vpc_cidr_block ]
    description = "Allow inbound HTTPS requests from MHS VPC"
  }

  tags = {
    Name = "${var.environment}-${var.cluster_name}-cloudwatch-endpoint-sg"
    Environment = var.environment
    CreatedBy = var.repo_name
  }
}