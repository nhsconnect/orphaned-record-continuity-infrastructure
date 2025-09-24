// TODO: PRMT-4648 - THIS IS A ONE-TIME MIGRATION SCRIPT LAMBDA. DELETE THIS .TF FILE AFTER USAGE!
resource "aws_lambda_function" "dynamo_migration" {
  filename         = var.dynamo_migration_lambda_zip
  function_name    = "${var.environment}-dynamo-migration-lambda"
  role             = aws_iam_role.dynamo_migration_lambda.arn
  handler          = "app.DynamoMigration.lambda_handler"
  layers           = [aws_lambda_layer_version.psycopg2.arn]
  source_code_hash = filebase64sha256(var.dynamo_migration_lambda_zip)
  runtime          = tolist(aws_lambda_layer_version.psycopg2.compatible_runtimes)[0] // Required for psycopg2 lambda layer to work
  timeout          = 900
  memory_size      = 1024
  tags = {
    Environment = var.environment
    CreatedBy   = var.repo_name
    Terraform   = "True"
  }
  vpc_config {
    subnet_ids         = module.deductions-private.deductions_private_private_subnets
    security_group_ids = [module.deductions-private.vpn_security_group, data.aws_security_group.ehr-transfer-service-ecs-task.id]
  }
  environment {
    variables = {
      ENVIRONMENT_NAME = var.environment
      OLD_TABLE_NAME   = "${var.environment}-ehr-transfer-service-transfer-tracker"
      NEW_TABLE_NAME   = "${var.environment}-ehr-transfer-tracker"
    }
  }

  depends_on = [
    data.archive_file.dynamo_migration_lambda,
    aws_iam_role_policy_attachment.lambda_vpc_access_execution
  ]
}

resource "aws_iam_role" "dynamo_migration_lambda" {
  name               = "${var.environment}-dynamo-migration-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy_attachment" "lambda_dynamodb_migration_execution" {
  role       = aws_iam_role.dynamo_migration_lambda.name
  policy_arn = data.aws_iam_policy.lambda_dynamodb_execution_role.arn
}

resource "aws_iam_role_policy_attachment" "lambda_dynamodb_migration_scan_put_update_and_kms_decrypt" {
  role       = aws_iam_role.dynamo_migration_lambda.name
  policy_arn = aws_iam_policy.lambda_dynamodb_migration_scan_put_update_and_kms_decrypt.arn
}

resource "aws_iam_role_policy_attachment" "lambda_rds_migration_access" {
  role       = aws_iam_role.dynamo_migration_lambda.name
  policy_arn = aws_iam_policy.lambda_rds_migration_access.arn
}

resource "aws_iam_role_policy_attachment" "lambda_vpc_access_execution" {
  role       = aws_iam_role.dynamo_migration_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_policy" "lambda_dynamodb_migration_scan_put_update_and_kms_decrypt" {
  name        = "lambda-dynamodb-scan-put-update-and-kms-decrypt-policy"
  description = "Allows Lambda to scan, put and update for the ${local.ehr_transfer_tracker_db_name} as well as decrypting a KMS key"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "DynamoDBScan",
        "Effect" : "Allow",
        "Action" : [
          "dynamodb:Scan"
        ],
        "Resource" : [
          "arn:aws:dynamodb:eu-west-2:${data.aws_caller_identity.current.account_id}:table/${var.environment}-ehr-transfer-service-transfer-tracker"
        ]
      },
      {
        "Sid" : "DynamoDBPutAndUpdate",
        "Effect" : "Allow",
        "Action" : [
          "dynamodb:PutItem",
          "dynamodb:UpdateItem"
        ],
        "Resource" : [
          "arn:aws:dynamodb:eu-west-2:${data.aws_caller_identity.current.account_id}:table/${var.environment}-ehr-transfer-tracker"
        ]
      },
      {
        "Sid" : "KMS",
        "Effect" : "Allow",
        "Action" : [
          "kms:Decrypt"
        ],
        "Resource" : [
          data.aws_kms_key.transfer_tracker_dynamodb.arn
        ]
      }
    ]
  })
}

data "aws_kms_key" "transfer_tracker_dynamodb" {
  key_id = "alias/transfer-tracker-dynamodb-encryption-kms-key"
}

resource "aws_iam_policy" "lambda_rds_migration_access" {
  name        = "lambda-rds-access-policy"
  description = "Allows Lambda to query data in RDS"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "VisualEditor0",
        "Effect" : "Allow",
        "Action" : [
          "rds:DescribeDBProxyTargetGroups",
          "ssm:ListCommands",
          "rds:DescribeDBRecommendations",
          "rds:DescribeGlobalClusters",
          "ssm:ListInstanceAssociations",
          "rds:DescribeRecommendations",
          "ssm:DescribeAutomationExecutions",
          "ssm:GetMaintenanceWindowTask",
          "ssm:DescribeMaintenanceWindowExecutionTaskInvocations",
          "rds:DescribeDBProxyTargets",
          "ssm:DescribeAutomationStepExecutions",
          "rds:DownloadDBLogFilePortion",
          "ssm:ListResourceDataSync",
          "rds:DescribeSourceRegions",
          "ssm:ListDocuments",
          "ssm:DescribeMaintenanceWindowsForTarget",
          "ssm:ListComplianceItems",
          "ssm:GetMaintenanceWindowExecutionTask",
          "ssm:GetMaintenanceWindowExecution",
          "ssm:ListResourceComplianceSummaries",
          "ssm:GetOpsMetadata",
          "ssm:DescribeOpsItems",
          "rds:DescribeReservedDBInstances",
          "rds:DescribeBlueGreenDeployments",
          "ssm:DescribeMaintenanceWindows",
          "rds:DescribeDbSnapshotTenantDatabases",
          "rds:DescribeIntegrations",
          "ssm:DescribeEffectivePatchesForPatchBaseline",
          "ssm:DescribeDocumentPermission",
          "ssm:GetAutomationExecution",
          "ssm:DescribePatchGroups",
          "ssm:GetDefaultPatchBaseline",
          "ssm:DescribeDocument",
          "rds:DescribeTenantDatabases",
          "ssm:ListAssociationVersions",
          "ssm:PutConfigurePackageResult",
          "ssm:DescribePatchGroupState",
          "rds:DescribeDBClusterBacktracks",
          "rds:DescribeReservedDBInstancesOfferings",
          "ssm:DescribeMaintenanceWindowExecutionTasks",
          "ssm:DescribeInstancePatchStatesForPatchGroup",
          "rds:DescribeRecommendationGroups",
          "rds:DescribeDBInstances",
          "rds:DescribeEngineDefaultClusterParameters",
          "ssm:GetDocument",
          "rds:DescribeDBProxies",
          "ssm:GetInventorySchema",
          "ssm:GetParametersByPath",
          "ssm:GetMaintenanceWindow",
          "rds:DescribeEventCategories",
          "rds:DescribeDBProxyEndpoints",
          "ssm:DescribeAssociationExecutionTargets",
          "rds:DescribeEvents",
          "ssm:GetPatchBaseline",
          "ssm:ListInventoryEntries",
          "ssm:DescribeAssociation",
          "ssm:ListOpsItemEvents",
          "ssm:DescribeSessions",
          "ssm:DescribePatchBaselines",
          "ssm:GetResourcePolicies",
          "ssm:DescribePatchProperties",
          "ssm:GetOpsSummary",
          "rds:DescribeDBSnapshotAttributes",
          "rds:ListTagsForResource",
          "ssm:DescribeInstanceInformation",
          "ssm:ListTagsForResource",
          "ssm:DescribeDocumentParameters",
          "ssm:GetCalendar",
          "ssm:GetCalendarState",
          "rds:DescribeDBInstanceAutomatedBackups",
          "ssm:ListDocumentVersions",
          "ssm:ListDocumentMetadataHistory",
          "ssm:DescribeMaintenanceWindowSchedule",
          "ssm:DescribeInstancePatches",
          "rds:DescribeEngineDefaultParameters",
          "ssm:GetParameter",
          "ssm:GetMaintenanceWindowExecutionTaskInvocation",
          "rds:DescribeDBClusterAutomatedBackups",
          "ssm:ListOpsMetadata",
          "ssm:DescribeParameters",
          "ssm:GetConnectionStatus",
          "rds:DescribeDBSnapshots",
          "ssm:GetOpsItem",
          "rds:DescribeDBSecurityGroups",
          "ssm:GetParameters",
          "ssm:ListOpsItemRelatedItems",
          "rds:DescribeValidDBInstanceModifications",
          "rds:DescribeOrderableDBInstanceOptions",
          "ssm:GetServiceSetting",
          "ssm:DescribeAssociationExecutions",
          "rds:DescribeCertificates",
          "ssm:ListCommandInvocations",
          "rds:DescribeOptionGroups",
          "rds:DescribeDBShardGroups",
          "rds:DescribeDBEngineVersions",
          "rds:DescribeDBSubnetGroups",
          "rds:DescribeExportTasks",
          "ssm:DescribeMaintenanceWindowTasks",
          "rds:DescribePendingMaintenanceActions",
          "rds:DescribeDBParameterGroups",
          "ssm:GetPatchBaselineForPatchGroup",
          "ssm:DescribeMaintenanceWindowExecutions",
          "ssm:GetManifest",
          "ssm:DescribeInstancePatchStates",
          "rds:DescribeDBParameters",
          "ssm:DescribeInstanceAssociationsStatus",
          "ssm:DescribeInstanceProperties",
          "rds:DescribeDBClusterSnapshotAttributes",
          "rds:DescribeDBClusterParameters",
          "rds:DescribeEventSubscriptions",
          "ssm:GetDeployablePatchSnapshotForInstance",
          "ssm:GetParameterHistory",
          "ssm:DescribeMaintenanceWindowTargets",
          "rds:DescribeDBLogFiles",
          "ssm:DescribeEffectiveInstanceAssociations",
          "ssm:DescribeInventoryDeletions",
          "ssm:GetInventory",
          "ssm:DescribeActivations",
          "ssm:GetCommandInvocation",
          "ssm:ListComplianceSummaries",
          "rds:DescribeDBClusterSnapshots",
          "rds:DescribeOptionGroupOptions",
          "rds:DownloadCompleteDBLogFile",
          "rds:DescribeDBClusterEndpoints",
          "ssm:ListAssociations",
          "rds:DescribeAccountAttributes",
          "rds:DescribeDBClusters",
          "rds:DescribeDBClusterParameterGroups",
          "ssm:DescribeAvailablePatches"
        ],
        "Resource" : "*"
      }
    ]
  })
}

data "archive_file" "dynamo_migration_lambda" {
  type             = "zip"
  source_dir       = "../dynamo-migration-lambda"
  output_path      = var.dynamo_migration_lambda_zip
  output_file_mode = "0644"
}

data "aws_security_group" "ehr-transfer-service-ecs-task" {
  name = "${var.environment}-ehr-transfer-service-ecs-task-sg"
}

variable "dynamo_migration_lambda_zip" {
  type        = string
  description = "path to zipfile containing lambda code for the dynamo-migration-lambda"
  default     = "../dynamo-migration-lambda/build/dynamo-migration-lambda.zip"
}

resource "aws_lambda_layer_version" "psycopg2" {
  layer_name          = "psycopg2"
  description         = "Contains the psycopg2 library to connect to PostgreSQL databases"
  filename            = "../lambda-layer-psycopg2/psycopg2.zip"
  source_code_hash    = filebase64sha256("../lambda-layer-psycopg2/psycopg2.zip")
  compatible_runtimes = ["python3.10"]
}