locals {
  ecr_lifecycle_policy_text = jsonencode({
    rules = [
      {
        rulePriority = 10
        description  = "Expire untagged images after var.untagged_expire_days days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = var.untagged_expire_days
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 20
        description  = "Keep only the last var.max_images_per_repo tagged images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = var.max_images_per_repo
        }
        action = { type = "expire" }
      }
    ]
  })
}

data "aws_caller_identity" "this" {}

resource "aws_secretsmanager_secret_policy" "dockerhub_ecr_ptc" {
  secret_arn = aws_secretsmanager_secret.dockerhub_ecr_ptc.arn
  policy     = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid      = "AllowEcrToReadForPullThroughCache",
        Effect   = "Allow",
        Principal = { Service = "ecr.amazonaws.com" },
        Action   = [
          "secretsmanager:DescribeSecret",
          "secretsmanager:GetSecretValue"
        ],
        Resource = aws_secretsmanager_secret.dockerhub_ecr_ptc.arn,
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.this.account_id
          },
          ArnLike = {
            "aws:SourceArn" = "arn:aws:ecr:${var.region}:${data.aws_caller_identity.this.account_id}:pull-through-cache-rule/*"
          }
        }
      }
    ]
  })
}

resource "aws_ecr_pull_through_cache_rule" "docker_hub" {
  ecr_repository_prefix = "nhsdev/nia-mhs-outbound"
  upstream_registry_url = "registry-1.docker.io"
  credential_arn        = aws_secretsmanager_secret.dockerhub_ecr_ptc.arn
  depends_on = [aws_secretsmanager_secret_policy.dockerhub_ecr_ptc]
}

resource "aws_ecr_repository_creation_template" "mhs_out" {
  prefix      = "nhsdev/nia-mhs-outbound"
  applied_for = ["PULL_THROUGH_CACHE"]

  image_tag_mutability = "IMMUTABLE"

  encryption_configuration {
    encryption_type = "AES256"
  }

  lifecycle_policy = local.ecr_lifecycle_policy_text
  description = "Defaults for repos auto-created under mhs-out/* by ECR PTC"
  repository_policy = data.aws_iam_policy_document.ecr_pull_through.json

}

resource "aws_secretsmanager_secret" "dockerhub_ecr_ptc" {
  name        = "ecr-pullthroughcache/dockerhub"
  description = "Docker Hub creds for ECR pull-through cache"
}

resource "aws_secretsmanager_secret_version" "dockerhub_ecr_ptc" {
  secret_id     = aws_secretsmanager_secret.dockerhub_ecr_ptc.id
  # Use Docker Hub username + PAT (read-only)
  secret_string = jsonencode({
    username    = var.dockerhub_username
    accessToken = var.dockerhub_access_token
  })
}
