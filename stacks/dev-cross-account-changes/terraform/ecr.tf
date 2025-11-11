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

resource "aws_ecr_pull_through_cache_rule" "docker_hub" {
  ecr_repository_prefix = "nhsdev/nia-mhs-outbound"
  upstream_registry_url = "registry-1.docker.io"
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
