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
  ecr_repository_prefix = "docker-hub"
  upstream_registry_url = "registry-1.docker.io"
  credential_arn        = aws_secretsmanager_secret.dockerhub_ecr_ptc.arn
  depends_on = [aws_secretsmanager_secret_policy.dockerhub_ecr_ptc]
}

resource "aws_ecr_repository_creation_template" "docker_hub" {
  prefix      = "docker-hub"
  applied_for = ["PULL_THROUGH_CACHE"]

  image_tag_mutability = "IMMUTABLE"

  encryption_configuration {
    encryption_type = "AES256"
  }

 lifecycle_policy = <<EOT
  {
    "rules": [
      {
        "rulePriority": 1,
        "description": "Expire images older than 14 days",
        "selection": {
          "tagStatus": "untagged",
          "countType": "sinceImagePushed",
          "countUnit": "days",
          "countNumber": 14
        },
        "action": {
          "type": "expire"
        }
      }
    ]
  }
  EOT
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

data "aws_iam_policy_document" "ecr_pull_through" {
  statement {
    sid    = "new policy"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [data.aws_caller_identity.this.account_id]
    }

    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeRepositories",
      "ecr:GetRepositoryPolicy",
      "ecr:ListImages",
      "ecr:DeleteRepository",
      "ecr:BatchDeleteImage",
      "ecr:SetRepositoryPolicy",
      "ecr:DeleteRepositoryPolicy",
    ]
  }
}