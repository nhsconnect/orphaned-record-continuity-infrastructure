provider "aws" {
  region = var.region
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.59.0"
    }
  }
}

module "end-of-transfer-service" {
  count       = var.is_end_of_transfer_service ? 1 : 0
  source      = "./modules/end-of-transfer-service/"
  environment = var.environment

  component_name    = var.component_name
  metric_namespace  = var.metric_namespace
  repo_name         = var.repo_name
  ecs_desired_count = var.ecs_desired_count
}

module "suspension-service" {
  count               = var.is_end_of_transfer_service ? 0 : 1
  source              = "./modules/suspension-service/"
  environment         = var.environment
  component_name      = var.component_name
  metric_namespace    = var.metric_namespace
  repo_name           = var.repo_name
  sns_sqs_role_arn    = aws_iam_role.sns_failure_feedback_role.arn
  ecs_cluster_name    = aws_ecs_cluster.ecs-cluster.name
  ecs_service_name    = aws_ecs_service.ecs-service.name
}
