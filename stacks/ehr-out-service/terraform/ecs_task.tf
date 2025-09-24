locals {
  task_role_arn           = aws_iam_role.component_ecs_role.arn
  task_execution_role     = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.environment}-${var.component_name}-EcsTaskRole"
  task_ecr_url            = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com"
  task_log_group          = "/nhs/deductions/${var.environment}-${data.aws_caller_identity.current.account_id}/${var.component_name}"
  environment_domain_name = data.aws_ssm_parameter.environment_domain_name.value
  environment_variables = [
    { name = "NHS_ENVIRONMENT", value = var.environment },
    {
      name  = "SERVICE_URL",
      value = "https://${var.component_name}.${local.environment_domain_name}"
    },
    {
      name  = "GP2GP_MESSENGER_SERVICE_URL",
      value = "https://gp2gp-messenger.${local.environment_domain_name}"
    },
    {
      name  = "EHR_REPO_SERVICE_URL",
      value = "https://ehr-repo.${local.environment_domain_name}"
    },
    { name = "REPOSITORY_ASID", value = data.aws_ssm_parameter.repository_asid.value },
    { name = "AWS_REGION", value = var.region },
    { name = "LOG_LEVEL", value = var.log_level },
    { name = "SQS_EHR_OUT_INCOMING_QUEUE_URL", value = aws_sqs_queue.service_incoming.id },
    { name = "FRAGMENT_TRANSFER_RATE_LIMIT_TIMEOUT_MILLISECONDS", value = "100" },
    { name = "DYNAMODB_NAME", value = data.aws_ssm_parameter.dynamodb_name.value },
    { name = "DYNAMODB_GSI_TIMEOUT_MILLISECONDS", value = data.aws_ssm_parameter.dynamodb_gsi_timeout_milliseconds.value }
  ]
  secret_environment_variables = [
    { name      = "GP2GP_MESSENGER_AUTHORIZATION_KEYS",
      valueFrom = data.aws_ssm_parameter.gp2gp_messenger_authorization_keys.arn
    },
    { name = "EHR_REPO_AUTHORIZATION_KEYS", valueFrom = data.aws_ssm_parameter.ehr_repo_authorization_keys.arn }
  ]
}

resource "aws_ecs_task_definition" "task" {
  family                   = var.component_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = local.task_execution_role
  task_role_arn            = local.task_role_arn


  container_definitions = templatefile("${path.module}/templates/ecs-task-def.tmpl", {
    container_name         = "${var.component_name}-container"
    ecr_url                = local.task_ecr_url,
    image_name             = "deductions/${var.component_name}",
    image_tag              = var.task_image_tag,
    cpu                    = var.task_cpu,
    memory                 = var.task_memory,
    readonlyRootFilesystem = true
    container_port         = var.port,
    host_port              = var.port,
    log_region             = var.region,
    log_group              = local.task_log_group,
    environment_variables  = jsonencode(local.environment_variables),
    secrets                = jsonencode(local.secret_environment_variables)
  })

  tags = {
    Environment = var.environment
    CreatedBy   = var.repo_name
  }
}

resource "aws_security_group" "ecs_tasks_sg" {
  name   = "${var.environment}-${var.component_name}-ecs-tasks-sg"
  vpc_id = data.aws_ssm_parameter.deductions_private_vpc_id.value

  ingress {
    description = "Allow traffic from internal ALB of gp to repo"
    protocol    = "tcp"
    from_port   = "3000"
    to_port     = "3000"
    security_groups = [
      aws_security_group.service_from_alb.id
    ]
  }

  egress {
    description = "Allow outbound to deductions private and deductions core"
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = [data.aws_vpc.deductions-private.cidr_block, data.aws_vpc.deductions-core.cidr_block]
  }

  egress {
    description = "Allow outbound to VPC Endpoints"
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    security_groups = concat(tolist(data.aws_vpc_endpoint.ecr-dkr.security_group_ids), tolist(data.aws_vpc_endpoint.ecr-api.security_group_ids),
    tolist(data.aws_vpc_endpoint.logs.security_group_ids), tolist(data.aws_vpc_endpoint.ssm.security_group_ids))
  }

  egress {
    description = "Allow outbound to S3 VPC Endpoint"
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = data.aws_vpc_endpoint.s3.cidr_blocks
  }

  egress {
    description     = "Allow outbound HTTPS traffic to dynamodb"
    protocol        = "tcp"
    from_port       = 443
    to_port         = 443
    prefix_list_ids = [data.aws_ssm_parameter.dynamodb_prefix_list_id.value]
  }

  tags = {
    Name        = "${var.environment}-${var.component_name}-ecs-tasks-sg"
    CreatedBy   = var.repo_name
    Environment = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "app_to_gp2gp_messenger" {
  type                     = "ingress"
  protocol                 = "TCP"
  from_port                = 443
  to_port                  = 443
  security_group_id        = data.aws_ssm_parameter.service-to-gp2gp-messenger-sg-id.value
  source_security_group_id = local.ecs_task_sg_id
}

resource "aws_security_group_rule" "app_to_ehr_repo" {
  type                     = "ingress"
  protocol                 = "TCP"
  from_port                = 443
  to_port                  = 443
  security_group_id        = data.aws_ssm_parameter.service-to-ehr-repo-sg-id.value
  source_security_group_id = aws_security_group.ecs_tasks_sg.id
}


resource "aws_security_group" "vpn_to_service_ecs" {
  count       = var.allow_vpn_to_ecs_tasks ? 1 : 0
  name        = "${var.environment}-vpn-to-${var.component_name}-ecs"
  description = "Controls access from vpn to ecs"
  vpc_id      = data.aws_ssm_parameter.deductions_private_vpc_id.value

  ingress {
    from_port       = 3000
    protocol        = "tcp"
    to_port         = 3000
    security_groups = [data.aws_ssm_parameter.vpn_sg_id.value]
  }

  tags = {
    Name        = "${var.environment}-vpn-to-${var.component_name}-sg"
    CreatedBy   = var.repo_name
    Environment = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_vpc" "deductions-private" {
  id = data.aws_ssm_parameter.deductions_private_vpc_id.value
}

data "aws_vpc" "deductions-core" {
  id = data.aws_ssm_parameter.deductions_core_vpc_id.value
}

data "aws_vpc_endpoint" "ecr-dkr" {
  vpc_id       = data.aws_ssm_parameter.deductions_private_vpc_id.value
  service_name = "com.amazonaws.${var.region}.ecr.dkr"
}

data "aws_vpc_endpoint" "ecr-api" {
  vpc_id       = data.aws_ssm_parameter.deductions_private_vpc_id.value
  service_name = "com.amazonaws.${var.region}.ecr.api"
}

data "aws_vpc_endpoint" "logs" {
  vpc_id       = data.aws_ssm_parameter.deductions_private_vpc_id.value
  service_name = "com.amazonaws.${var.region}.logs"
}

data "aws_vpc_endpoint" "ssm" {
  vpc_id       = data.aws_ssm_parameter.deductions_private_vpc_id.value
  service_name = "com.amazonaws.${var.region}.ssm"
}

data "aws_vpc_endpoint" "s3" {
  vpc_id       = data.aws_ssm_parameter.deductions_private_vpc_id.value
  service_name = "com.amazonaws.${var.region}.s3"
}

data "aws_ssm_parameter" "service-to-gp2gp-messenger-sg-id" {
  name = "/repo/${var.environment}/output/prm-deductions-gp2gp-messenger/service-to-gp2gp-messenger-sg-id"
}

data "aws_ssm_parameter" "service-to-ehr-repo-sg-id" {
  name = "/repo/${var.environment}/output/prm-deductions-ehr-repository/service-to-ehr-repo-sg-id"
}

data "aws_ssm_parameter" "dynamodb_prefix_list_id" {
  name = "/repo/${var.environment}/output/prm-deductions-infra/dynamodb_prefix_list_id"
}

data "aws_ssm_parameter" "dynamodb_gsi_timeout_milliseconds" {
  name = "/repo/${var.environment}/output/prm-repo-ehr-out-service/dynamodb_gsi_timeout_milliseconds"
}