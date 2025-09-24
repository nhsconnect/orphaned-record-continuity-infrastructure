locals {
  task_role_arn         = aws_iam_role.component-ecs-role.arn
  task_execution_role   = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.environment}-${var.component_name}-EcsTaskRole"
  task_ecr_url          = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com"
  task_log_group        = "/nhs/deductions/${var.environment}-${data.aws_caller_identity.current.account_id}/${var.component_name}"
  env_domain_name       = data.aws_ssm_parameter.environment_domain_name.value
  environment_variables = [
    { name = "NHS_ENVIRONMENT", value = var.environment },
    { name = "AWS_REGION", value = var.region },
    { name = "LOG_LEVEL", value = var.log_level },
    { name = "RE_REGISTRATIONS_QUEUE_NAME", value = aws_sqs_queue.re_registrations.name },
    { name = "RE_REGISTRATIONS_AUDIT_QUEUE_NAME", value = aws_sqs_queue.re_registration_audit_uploader.name },
    { name = "ACTIVE_SUSPENSIONS_QUEUE_NAME", value = aws_sqs_queue.active_suspensions.name },
    {
      name  = "PDS_ADAPTOR_SERVICE_URL",
      value = "https://pds-adaptor.${local.env_domain_name}"
    },
    { name = "PDS_ADAPTOR_AUTH_PASSWORD", value = data.aws_ssm_parameter.pds_adaptor_auth_password.value },
    { name = "RE_REGISTRATIONS_AUDIT_SNS_TOPIC_ARN", value = aws_sns_topic.re_registration_audit_topic.arn },
    { name = "CAN_SEND_DELETE_EHR_REQUEST", value = tostring(var.toggle_can_send_delete_ehr_request) },
    {
      name  = "EHR_REPO_URL",
      value = "https://ehr-repo.${local.env_domain_name}"
    },
    {
      name  = "RE_REGISTRATION_SERVICE_AUTHORIZATION_KEYS_FOR_EHR_REPO",
      value = data.aws_ssm_parameter.re_registration_service_authorization_keys_for_ehr_repo.value
    },
    { name = "ACTIVE_SUSPENSIONS_DYNAMODB_TABLE_NAME", value = aws_dynamodb_table.active_suspensions.name }
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
    container_name        = "${var.component_name}-container"
    ecr_url               = local.task_ecr_url,
    image_name            = "repo/${var.component_name}",
    image_tag             = var.task_image_tag,
    cpu                   = var.task_cpu,
    memory                = var.task_memory,
    log_region            = var.region,
    log_group             = local.task_log_group,
    environment_variables = jsonencode(local.environment_variables)
  })

  tags = {
    Environment = var.environment
    CreatedBy   = var.repo_name
  }
}

resource "aws_security_group" "ecs-tasks-sg" {
  name   = "${var.environment}-${var.component_name}-ecs-tasks-sg"
  vpc_id = data.aws_ssm_parameter.deductions_private_vpc_id.value

  egress {
    description = "Allow outbound to deductions private and deductions core"
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = [data.aws_vpc.deductions-private.cidr_block, data.aws_vpc.deductions-core.cidr_block]
  }

  egress {
    description     = "Allow outbound HTTPS traffic to s3"
    protocol        = "tcp"
    from_port       = 443
    to_port         = 443
    prefix_list_ids = [data.aws_ssm_parameter.s3_prefix_list_id.value]
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
}

resource "aws_security_group_rule" "ehr-transfer-service-to-ehr-repo" {
  type                     = "ingress"
  protocol                 = "TCP"
  from_port                = 443
  to_port                  = 443
  security_group_id        = data.aws_ssm_parameter.service-to-ehr-repo-sg-id.value
  source_security_group_id = aws_security_group.ecs-tasks-sg.id
}

resource "aws_ssm_parameter" "ecs_task_security_group" {
  name  = "/repo/${var.environment}/output/${var.component_name}/ecs-sg-id"
  type  = "String"
  value = aws_security_group.ecs-tasks-sg.id

  tags = {
    Name        = "${var.environment}-${var.component_name}-ecs-task-security-group-id"
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}

data "aws_ssm_parameter" "s3_prefix_list_id" {
  name = "/repo/${var.environment}/output/prm-deductions-infra/s3_prefix_list_id"
}

data "aws_ssm_parameter" "dynamodb_prefix_list_id" {
  name = "/repo/${var.environment}/output/prm-deductions-infra/dynamodb_prefix_list_id"
}
