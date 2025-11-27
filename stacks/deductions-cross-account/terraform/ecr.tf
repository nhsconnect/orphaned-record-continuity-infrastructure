resource "aws_ecr_repository" "ehr_out_service" {
  name                 = "deductions/ehr-out-service"
  image_tag_mutability = "IMMUTABLE"
  tags = {
    CreatedBy = var.repo_name
  }
}

resource "aws_ecr_repository" "gp2gp-adaptor" {
  name                 = "deductions/gp2gp-adaptor"
  image_tag_mutability = var.immutable_ecr_repositories ? "IMMUTABLE" : "MUTABLE"
  tags = {
    CreatedBy = var.repo_name
  }
}

resource "aws_ecr_repository" "gp2gp-messenger" {
  name                 = "deductions/gp2gp-messenger"
  image_tag_mutability = var.immutable_ecr_repositories ? "IMMUTABLE" : "MUTABLE"
  tags = {
    CreatedBy = var.repo_name
  }
}

resource "aws_ecr_repository" "ehr-transfer-service" {
  name                 = "deductions/ehr-transfer-service"
  image_tag_mutability = var.immutable_ecr_repositories ? "IMMUTABLE" : "MUTABLE"
  tags = {
    CreatedBy = var.repo_name
  }
}

resource "aws_ecr_repository" "ehr-repo" {
  name                 = "deductions/ehr-repo"
  image_tag_mutability = var.immutable_ecr_repositories ? "IMMUTABLE" : "MUTABLE"
  tags = {
    CreatedBy = var.repo_name
  }
}

resource "aws_ecr_repository" "mhs-inbound" {
  name                 = "mhs-inbound"
  image_tag_mutability = var.immutable_ecr_repositories ? "IMMUTABLE" : "MUTABLE"
  tags = {
    CreatedBy = var.repo_name
  }
}

resource "aws_ecr_repository" "mhs-outbound" {
  name                 = "mhs-outbound"
  image_tag_mutability = var.immutable_ecr_repositories ? "IMMUTABLE" : "MUTABLE"
  tags = {
    CreatedBy = var.repo_name
  }
}

resource "aws_ecr_repository" "nia_mhs_inbound" {
  name                 = "docker-hub/nhsdev/nia-mhs-inbound"
  image_tag_mutability = var.immutable_ecr_repositories ? "IMMUTABLE" : "MUTABLE"
  tags = {
    CreatedBy = var.repo_name
  }
}

resource "aws_ecr_repository" "nia_mhs_outbound" {
  name                 = "docker-hub/nhsdev/nia-mhs-outbound"
  image_tag_mutability = var.immutable_ecr_repositories ? "IMMUTABLE" : "MUTABLE"
  tags = {
    CreatedBy = var.repo_name
  }
}

resource "aws_ecr_repository" "pds_adaptor" {
  name                 = "deductions/pds-adaptor"
  image_tag_mutability = var.immutable_ecr_repositories ? "IMMUTABLE" : "MUTABLE"
  tags = {
    CreatedBy = var.repo_name
  }
}

resource "aws_ecr_repository" "mesh-forwarder" {
  name                 = "deductions/mesh-forwarder"
  image_tag_mutability = var.immutable_ecr_repositories ? "IMMUTABLE" : "MUTABLE"
  tags = {
    CreatedBy = var.repo_name
  }
}

resource "aws_ecr_repository" "nems-event-processor" {
  name                 = "deductions/nems-event-processor"
  image_tag_mutability = var.immutable_ecr_repositories ? "IMMUTABLE" : "MUTABLE"
  tags = {
    CreatedBy = var.repo_name
  }
}

resource "aws_ecr_repository" "suspension-service" {
  name                 = "repo/suspension-service"
  image_tag_mutability = var.immutable_ecr_repositories ? "IMMUTABLE" : "MUTABLE"
  tags = {
    CreatedBy = var.repo_name
  }
}

resource "aws_ecr_repository" "pds-fhir-stub" {
  name                 = "repo/pds-fhir-stub"
  image_tag_mutability = var.immutable_ecr_repositories ? "IMMUTABLE" : "MUTABLE"
  tags = {
    CreatedBy = var.repo_name
  }
}

resource "aws_ecr_repository" "re_registration_service" {
  name                 = "repo/re-registration-service"
  image_tag_mutability = var.immutable_ecr_repositories ? "IMMUTABLE" : "MUTABLE"
  tags = {
    CreatedBy = var.repo_name
  }
}

resource "aws_ecr_repository" "gp_registrations_mi_forwarder" {
  name                 = "repo/gp-registrations-mi-forwarder"
  image_tag_mutability = var.immutable_ecr_repositories ? "IMMUTABLE" : "MUTABLE"
  tags = {
    CreatedBy = var.repo_name
  }
}

data "aws_caller_identity" "this" {}

resource "aws_secretsmanager_secret_policy" "dockerhub_ecr_ptc" {
  secret_arn = aws_secretsmanager_secret.dockerhub_ecr_ptc.arn
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowEcrToReadForPullThroughCache",
        Effect = "Allow",
        Principal = {
          Service = "ecr.amazonaws.com"
        },
        Action = [
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

resource "aws_secretsmanager_secret" "dockerhub_ecr_ptc" {
  name        = "ecr-pullthroughcache/dockerhub"
  description = "Docker Hub creds for ECR pull-through cache"
}

resource "aws_secretsmanager_secret_version" "dockerhub_ecr_ptc" {
  secret_id = aws_secretsmanager_secret.dockerhub_ecr_ptc.id

  secret_string = jsonencode({
    username    = var.dockerhub_username
    accessToken = var.dockerhub_access_token
  })
}
