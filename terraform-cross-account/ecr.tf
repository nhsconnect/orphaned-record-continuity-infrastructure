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

# mhs-in/*
resource "aws_ecr_repository_creation_template" "mhs_in" {
  prefix      = "mhs-in"
  applied_for = ["PULL_THROUGH_CACHE"]

  image_tag_mutability = "IMMUTABLE"

  encryption_configuration {
    encryption_type = "AES256"
  }

  lifecycle_policy = local.ecr_lifecycle_policy_text

  description = "Defaults for repos auto-created under mhs-in/* by ECR PTC"
}

# mhs-out/*
resource "aws_ecr_repository_creation_template" "mhs_out" {
  prefix      = "mhs-out"
  applied_for = ["PULL_THROUGH_CACHE"]

  image_tag_mutability = "IMMUTABLE"

  encryption_configuration {
    encryption_type = "AES256"
  }

  lifecycle_policy = local.ecr_lifecycle_policy_text

  description = "Defaults for repos auto-created under mhs-out/* by ECR PTC"
}

resource "aws_ecr_pull_through_cache_rule" "mhs_in" {
  ecr_repository_prefix = "mhs-in"
  upstream_registry_url = "registry-1.docker.io"
}

resource "aws_ecr_pull_through_cache_rule" "mhs_out" {
  ecr_repository_prefix = "mhs-out"
  upstream_registry_url = "registry-1.docker.io"
}

resource "aws_ecr_repository" "ehr_out_service" {
  name = "deductions/ehr-out-service"
  image_tag_mutability = "IMMUTABLE"
  tags = {
    CreatedBy = var.repo_name
  }
}

resource "aws_ecr_repository" "gp2gp-adaptor" {
  name = "deductions/gp2gp-adaptor"
  image_tag_mutability = var.immutable_ecr_repositories ? "IMMUTABLE" : "MUTABLE"
  tags = {
    CreatedBy = var.repo_name
  }
}

resource "aws_ecr_repository" "gp2gp-messenger" {
  name = "deductions/gp2gp-messenger"
  image_tag_mutability = var.immutable_ecr_repositories ? "IMMUTABLE" : "MUTABLE"
  tags = {
    CreatedBy = var.repo_name
  }
}

resource "aws_ecr_repository" "ehr-transfer-service" {
  name = "deductions/ehr-transfer-service"
  image_tag_mutability = var.immutable_ecr_repositories ? "IMMUTABLE" : "MUTABLE"
  tags = {
    CreatedBy = var.repo_name
  }
}

resource "aws_ecr_repository" "ehr-repo" {
  name = "deductions/ehr-repo"
  image_tag_mutability = var.immutable_ecr_repositories ? "IMMUTABLE" : "MUTABLE"
  tags = {
    CreatedBy = var.repo_name
  }
}

resource "aws_ecr_repository" "mhs-inbound" {
  name = "mhs-inbound"
  image_tag_mutability = var.immutable_ecr_repositories ? "IMMUTABLE" : "MUTABLE"
  tags = {
    CreatedBy = var.repo_name
  }
}

resource "aws_ecr_repository" "mhs-outbound" {
  name = "mhs-outbound"
  image_tag_mutability = var.immutable_ecr_repositories ? "IMMUTABLE" : "MUTABLE"
  tags = {
    CreatedBy = var.repo_name
  }
}

resource "aws_ecr_repository" "pds_adaptor" {
  name = "deductions/pds-adaptor"
  image_tag_mutability = var.immutable_ecr_repositories ? "IMMUTABLE" : "MUTABLE"
  tags = {
    CreatedBy = var.repo_name
  }
}

resource "aws_ecr_repository" "mesh-forwarder" {
  name = "deductions/mesh-forwarder"
  image_tag_mutability = var.immutable_ecr_repositories ? "IMMUTABLE" : "MUTABLE"
  tags = {
    CreatedBy = var.repo_name
  }
}

resource "aws_ecr_repository" "nems-event-processor" {
  name = "deductions/nems-event-processor"
  image_tag_mutability = var.immutable_ecr_repositories ? "IMMUTABLE" : "MUTABLE"
  tags = {
    CreatedBy = var.repo_name
  }
}

resource "aws_ecr_repository" "suspension-service" {
  name = "repo/suspension-service"
  image_tag_mutability = var.immutable_ecr_repositories ? "IMMUTABLE" : "MUTABLE"
  tags = {
    CreatedBy = var.repo_name
  }
}

resource "aws_ecr_repository" "pds-fhir-stub" {
  name = "repo/pds-fhir-stub"
  image_tag_mutability = var.immutable_ecr_repositories ? "IMMUTABLE" : "MUTABLE"
  tags = {
    CreatedBy = var.repo_name
  }
}

resource "aws_ecr_repository" "re_registration_service" {
  name = "repo/re-registration-service"
  image_tag_mutability = var.immutable_ecr_repositories ? "IMMUTABLE" : "MUTABLE"
  tags = {
    CreatedBy = var.repo_name
  }
}

resource "aws_ecr_repository" "gp_registrations_mi_forwarder" {
  name = "repo/gp-registrations-mi-forwarder"
  image_tag_mutability = var.immutable_ecr_repositories ? "IMMUTABLE" : "MUTABLE"
  tags = {
    CreatedBy = var.repo_name
  }
}
