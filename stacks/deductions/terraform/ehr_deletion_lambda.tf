resource "aws_lambda_function" "ehr_hard_deletion" {
  filename         = var.ehr_hard_deletion_lambda_zip
  function_name    = "${var.environment}-ehr-hard-deletion-lambda"
  role             = aws_iam_role.ehr_hard_deletion_lambda.arn
  handler          = "EhrHardDeletion.lambda_handler"
  source_code_hash = filebase64sha256(var.ehr_hard_deletion_lambda_zip)
  runtime          = "python3.12"
  timeout          = 300
  tags = {
    Environment = var.environment
    CreatedBy   = var.repo_name
    Terraform   = "True"
  }
  environment {
    variables = {
      S3_REPO_BUCKET = data.aws_s3_bucket.ehr_repo_bucket.bucket
      #S3_LARGE_MESSAGES_BUCKET=data.aws_s3_bucket.xxx.bucket
    }
  }

  depends_on = [
    data.archive_file.ehr_hard_deletion_lambda
  ]
}

resource "aws_lambda_event_source_mapping" "ehr_transfer_tracker_dynamodb_to_hard_delete_lambda" {
  event_source_arn  = module.ehr_transfer_tracker_dynamodb_table.dynamodb_table_stream_arn
  function_name     = aws_lambda_function.ehr_hard_deletion.arn
  starting_position = "TRIM_HORIZON"

  filter_criteria {
    filter {
      pattern = jsonencode({
        "userIdentity" = {
          "type" : [
            "Service"
          ],
          "principalId" : [
            "dynamodb.amazonaws.com"
          ]
        },
        "dynamodb" : {
          "Keys" : {
            "Layer" : {
              "S" : ["CONVERSATION"]
            }
          }
        }
      })
    }
  }
}

resource "aws_iam_role" "ehr_hard_deletion_lambda" {
  name               = "${var.environment}-ehr-hard-deletion-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy_attachment" "lambda_dynamodb_execution" {
  role       = aws_iam_role.ehr_hard_deletion_lambda.name
  policy_arn = data.aws_iam_policy.lambda_dynamodb_execution_role.arn
}

resource "aws_iam_role_policy_attachment" "lambda_s3_repo_object_deletion" {
  role       = aws_iam_role.ehr_hard_deletion_lambda.name
  policy_arn = aws_iam_policy.lambda_s3_repo_object_deletion.arn
}

resource "aws_iam_role_policy_attachment" "lambda_dynamodb_query" {
  role       = aws_iam_role.ehr_hard_deletion_lambda.name
  policy_arn = aws_iam_policy.lambda_dynamodb_query.arn
}

resource "aws_iam_policy" "lambda_s3_repo_object_deletion" {
  name        = "lambda-s3-repo-object-deletion-policy"
  description = "Allows Lambda to delete objects in the ${data.aws_s3_bucket.ehr_repo_bucket.id}"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:ListBucket",
          "s3:ListBucketVersions"
        ],
        Resource = [
          "${data.aws_s3_bucket.ehr_repo_bucket.arn}"
        ],
      },
      {
        Effect = "Allow",
        Action = [
          "s3:DeleteObject",
          "s3:DeleteObjectVersion"
        ],
        Resource = [
          "${data.aws_s3_bucket.ehr_repo_bucket.arn}/*"
        ],
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_dynamodb_query" {
  name        = "lambda-dynamodb-query-policy"
  description = "Allows Lambda to query data in the ${local.ehr_transfer_tracker_db_name}"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "EhrTransferTrackerQueryAccess",
        Effect = "Allow",
        Action = [
          "dynamodb:Query",
        ],
        Resource = module.ehr_transfer_tracker_dynamodb_table.dynamodb_table_arn
      }
    ],
  })
}

data "aws_iam_policy" "lambda_dynamodb_execution_role" {
  arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaDynamoDBExecutionRole"
}

data "archive_file" "ehr_hard_deletion_lambda" {
  type             = "zip"
  source_file      = "../ehr-hard-deletion-lambda/EhrHardDeletion.py"
  output_path      = var.ehr_hard_deletion_lambda_zip
  output_file_mode = "0644"
}