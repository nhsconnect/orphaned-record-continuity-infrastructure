locals {
  task_role_arn       = aws_iam_role.component-ecs-role.arn
  task_execution_role = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.environment}-${var.component_name}-EcsTaskRole"
  task_ecr_url        = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com"
  task_log_group      = "/nhs/deductions/${var.environment}-${data.aws_caller_identity.current.account_id}/${var.component_name}"
  environment_variables = [
    { name = "NHS_ENVIRONMENT", value = var.environment },
    { name = "AWS_REGION", value = var.region },
    { name = "LOG_LEVEL", value = var.log_level },
    { name = "PDS_FHIR_ENDPOINT", value = data.aws_ssm_parameter.pds_fhir_endpoint.value },
    { name = "ACCESS_TOKEN_ENDPOINT", value = data.aws_ssm_parameter.access_token_endpoint.value },
    { name = "JWT_KEY_ID", value = data.aws_ssm_parameter.jwt_key_id.value }
  ]
  secret_environment_variables = [
    { name = "JWT_PRIVATE_KEY", valueFrom =  data.aws_ssm_parameter.jwt_private_key.arn },
    { name = "JWT_API_KEY", valueFrom = data.aws_ssm_parameter.jwt_api_key.arn }
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
    image_name            = "deductions/${var.component_name}",
    image_tag             = var.task_image_tag,
    cpu                   = var.task_cpu,
    memory                = var.task_memory,
    container_port        = var.port,
    host_port             = var.port,
    log_region            = var.region,
    log_group             = local.task_log_group,
    environment_variables = jsonencode(local.environment_variables),
    secrets               = jsonencode(local.secret_environment_variables)
  })

  tags = {
    Environment = var.environment
    CreatedBy= var.repo_name
  }
}

resource "aws_security_group" "ecs-tasks-sg" {
  name        = "${var.environment}-${var.component_name}-ecs-tasks-sg"
  vpc_id      = data.aws_ssm_parameter.deductions_private_vpc_id.value

  ingress {
    description     = "Allow traffic from internal ALB of pds adaptor"
    protocol        = "tcp"
    from_port       = var.port
    to_port         = var.port
    security_groups = [
      aws_security_group.pds_adaptor_alb.id
    ]
  }

  egress {
    description = "Allow all outbound HTTPS traffic"
    protocol         = "tcp"
    from_port        = 443
    to_port          = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-${var.component_name}-ecs-tasks-sg"
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}

resource "aws_ssm_parameter" "ecs_tasks_sq" {
  name  = "/repo/${var.environment}/output/${var.component_name}/ecs-sg-id"
  type  = "String"
  value = aws_security_group.ecs-tasks-sg.id
}
