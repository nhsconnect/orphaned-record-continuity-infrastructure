###################
# VPC endpoints
#
# The MHS VPC does not have public ip addresses,
# so in order to access various AWS services, we
# need to have some VPC endpoints. This keeps
# traffic to AWS services within the AWS network.
###################

# DynamoDB VPC endpoint
resource "aws_vpc_endpoint" "dynamodb_endpoint" {
  vpc_id = var.mhs_vpc_id
  service_name = "com.amazonaws.${var.region}.dynamodb"
  route_table_ids = aws_route_table.mhs.*.id

  tags = {
    Name = "${var.environment}-${var.cluster_name}-dynamodb-endpoint"
    Environment = var.environment
    CreatedBy = var.repo_name
  }
}

# S3 VPC endpoint
resource "aws_vpc_endpoint" "s3_endpoint" {
  vpc_id = var.mhs_vpc_id
  service_name = "com.amazonaws.${var.region}.s3"
  route_table_ids = aws_route_table.mhs.*.id


  tags = {
    Name = "${var.environment}-${var.cluster_name}-s3-endpoint"
    Environment = var.environment
    CreatedBy = var.repo_name
  }
}
