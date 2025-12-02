# The MHS DynamoDB state table, for storing state for each message handled
resource "aws_dynamodb_table" "mhs_state_table" {
  name           = "${var.environment}-${var.cluster_name}-mhs-state"
  hash_key       = "key"
  read_capacity  = var.mhs_state_table_read_capacity
  write_capacity = var.mhs_state_table_write_capacity
  #  deletion_protection_enabled = true

  point_in_time_recovery {
    enabled = true
  }

  attribute {
    name = "key"
    type = "S"
  }

  tags = {
    Name        = "${var.environment}-${var.cluster_name}-mhs-state-table"
    Environment = var.environment
    CreatedBy   = var.repo_name
  }
}

# The MHS DynamoDB sync-async table, used as a queue for the sync-async workflow
resource "aws_dynamodb_table" "mhs_sync_async_table" {
  name           = "${var.environment}-${var.cluster_name}-mhs-sync-async-state"
  hash_key       = "key"
  read_capacity  = var.mhs_sync_async_table_read_capacity
  write_capacity = var.mhs_sync_async_table_write_capacity
  # deletion_protection_enabled = true

  point_in_time_recovery {
    enabled = true
  }

  attribute {
    name = "key"
    type = "S"
  }

  tags = {
    Name        = "${var.environment}-${var.cluster_name}-mhs-sync-async-table"
    Environment = var.environment
    CreatedBy   = var.repo_name
  }
}