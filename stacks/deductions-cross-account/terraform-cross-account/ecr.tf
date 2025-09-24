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
