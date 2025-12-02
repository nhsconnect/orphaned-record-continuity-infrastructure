locals {
  ehr_transfer_tracker_db_name = "${var.environment}-ehr-transfer-tracker"
}

module "ehr_transfer_tracker_dynamodb_table" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "4.0.0"

  name      = local.ehr_transfer_tracker_db_name
  hash_key  = "InboundConversationId"
  range_key = "Layer"
  global_secondary_indexes = [
    {
      name            = "NhsNumberSecondaryIndex"
      hash_key        = "NhsNumber"
      projection_type = "ALL"
    },
    {
      name            = "OutboundConversationIdSecondaryIndex"
      hash_key        = "OutboundConversationId"
      projection_type = "ALL"
    }
  ]

  attributes = [
    {
      "name" : "InboundConversationId",
      "type" : "S"
    },
    {
      "name" : "Layer",
      "type" : "S"
    },
    {
      "name" : "NhsNumber",
      "type" : "S"
    },
    {
      "name" : "OutboundConversationId",
      "type" : "S"
    }
  ]

  deletion_protection_enabled    = true
  point_in_time_recovery_enabled = true
  server_side_encryption_enabled = true

  ttl_attribute_name = "DeletedAt"
  ttl_enabled        = true

  stream_enabled   = true
  stream_view_type = "OLD_IMAGE"

  tags = {
    Terraform   = "true"
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}
