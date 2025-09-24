locals {
  task_role_arn       = aws_iam_role.component-ecs-role.arn
  task_execution_role = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.environment}-${var.component_name}-EcsTaskRole"
  task_ecr_url        = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com"
  task_log_group      = "/nhs/deductions/${var.environment}-${data.aws_caller_identity.current.account_id}/${var.component_name}"
  environment_variables = [
    { name = "NHS_ENVIRONMENT", value = var.environment },
    { name = "AWS_REGION", value = var.region },
    { name = "LOG_LEVEL", value = var.log_level },
    { name = "UNHANDLED_EVENTS_SNS_TOPIC_ARN", value = aws_sns_topic.unhandled_events.arn },
    { name = "SUSPENSIONS_SNS_TOPIC_ARN", value = aws_sns_topic.suspensions.arn },
    { name = "DEAD_LETTER_QUEUE_SNS_TOPIC_ARN", value = aws_sns_topic.dlq.arn },
    { name = "NEMS_EVENTS_AUDIT_SNS_TOPIC_ARN", value = aws_sns_topic.nems_audit.arn },
    { name = "RE_REGISTRATION_SNS_TOPIC_ARN", value = aws_sns_topic.re_registrations_topic.arn },
    { name = "NEMS_EVENTS_QUEUE_NAME", value = aws_sqs_queue.incoming_nems_events.name },
    { name = "DYNAMODB_NAME", value = data.aws_ssm_parameter.dynamodb_name.value }
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
    log_region            = var.region,
    log_group             = local.task_log_group,
    environment_variables = jsonencode(local.environment_variables)
  })

  tags = {
    Environment = var.environment
    CreatedBy = var.repo_name
  }
}

resource "aws_security_group" "ecs-tasks-sg" {
  name        = "${var.environment}-${var.component_name}-ecs-tasks-sg"
  vpc_id      = data.aws_ssm_parameter.deductions_private_vpc_id.value

  egress {
    description = "Allow all outbound HTTPS traffic in vpc"
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = [data.aws_vpc.private_vpc.cidr_block]
  }

  egress {
    description     = "Allow outbound HTTPS traffic to s3"
    protocol        = "tcp"
    from_port       = 443
    to_port         = 443
    prefix_list_ids = [data.aws_ssm_parameter.s3_prefix_list_id.value]
  }

  tags = {
    Name = "${var.environment}-${var.component_name}-ecs-tasks-sg"
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}

data "aws_vpc" "private_vpc" {
  id = data.aws_ssm_parameter.deductions_private_vpc_id.value
}

data "aws_ssm_parameter" "s3_prefix_list_id" {
  name = "/repo/${var.environment}/output/prm-deductions-infra/s3_prefix_list_id"
}