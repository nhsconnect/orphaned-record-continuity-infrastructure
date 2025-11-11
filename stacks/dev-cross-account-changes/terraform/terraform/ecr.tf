resource "aws_ecr_pull_through_cache_rule" "docker_hub" {
  ecr_repository_prefix = "docker-hub"
  upstream_registry_url = "registry-1.docker.io"
}

resource "aws_ecr_repository_creation_template" "mhs-in" {
  prefix               = "docker-hub"
  description          = "ECR PTC creation template for MHS IN"
  image_tag_mutability = "MUTABLE"

  applied_for = [
    "PULL_THROUGH_CACHE",
  ]

  encryption_configuration {
    encryption_type = "AES256"
  }

  repository_policy = data.aws_iam_policy_document.ecr_pull_through.json

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
}
