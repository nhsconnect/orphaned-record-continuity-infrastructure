# Security group for Interface VPC Endpoints (ECR API/DKR)
resource "aws_security_group" "vpce_ecr" {
  name        = "${var.environment}-${var.component_name}-vpce-ecr"
  description = "SG for ECR Interface VPC Endpoints"
  vpc_id      = local.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = local.private_subnet_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.default_tags, {
    Name = "${var.environment}-${var.component_name}-vpce-ecr"
  })
}

# Interface: ECR API
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = local.vpc_id
  service_name        = "com.amazonaws.${var.region}.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = local.private_subnets
  security_group_ids  = [aws_security_group.vpce_ecr.id]
  private_dns_enabled = true

  tags = merge(var.default_tags, {
    Name = "${var.environment}-${var.component_name}-vpce-ecr-api"
  })
}

# Interface: ECR DKR
resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = local.vpc_id
  service_name        = "com.amazonaws.${var.region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = local.private_subnets
  security_group_ids  = [aws_security_group.vpce_ecr.id]
  private_dns_enabled = true

  tags = merge(var.default_tags, {
    Name = "${var.environment}-${var.component_name}-vpce-ecr-dkr"
  })
}

# Gateway: S3 (ECR layers)
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = local.vpc_id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = local.private_route_table_ids

  tags = merge(var.default_tags, {
    Name = "${var.environment}-${var.component_name}-vpce-s3"
  })
}
