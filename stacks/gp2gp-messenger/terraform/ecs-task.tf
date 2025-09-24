locals {
  task_role_arn       = aws_iam_role.gp2gp.arn
  task_execution_role = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.environment}-${var.component_name}-EcsTaskRole"
  task_ecr_url        = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com"
  task_log_group      = "/nhs/deductions/${var.environment}-${data.aws_caller_identity.current.account_id}/${var.component_name}"
  environment_variables = [
    { name = "GP2GP_MESSENGER_REPOSITORY_ODS_CODE", value = data.aws_ssm_parameter.GP2GP_MESSENGER_REPOSITORY_ODS_CODE.value },
    { name = "GP2GP_MESSENGER_REPOSITORY_ASID", value = data.aws_ssm_parameter.GP2GP_MESSENGER_REPOSITORY_ASID.value },
    { name = "NHS_ENVIRONMENT", value = var.environment },
    { name = "GP2GP_MESSENGER_MHS_OUTBOUND_URL", value = data.aws_ssm_parameter.GP2GP_MESSENGER_MHS_OUTBOUND_URL.value },
    { name = "NHS_NUMBER_PREFIX", value = data.aws_ssm_parameter.nhs_number_prefix.value },
    { name = "SDS_FHIR_API_KEY", value = data.aws_ssm_parameter.sds_fhir_api_key.value },
    { name = "SDS_FHIR_URL", value = data.aws_ssm_parameter.sds_fhir_url.value },
    { name = "LOG_LEVEL", value = var.log_level },
    { name = "SPINE_ORG_CODE", value = var.spine_org_code },
    { name = "PDS_ASID", value = data.aws_ssm_parameter.pds_asid.value },
    { name = "SQS_OBSERVABILITY_QUEUE_URL", value = aws_sqs_queue.hl7_message_sent_observability.id },
    { name = "REQUEST_EHR_ONLY_FOR_SAFE_LISTED_ODS_CODES", value = tostring(var.request_ehr_only_for_safe_listed_ods_codes) },
    { name = "SAFE_LISTED_ODS_CODES", value = data.aws_ssm_parameter.safe_listed_ods_codes.value }
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
    container_name        = "${var.component_name}-container",
    ecr_url               = local.task_ecr_url,
    image_name            = "deductions/${var.component_name}",
    image_tag             = var.task_image_tag,
    cpu                   = var.task_cpu,
    memory                = var.task_memory,
    container_port        = var.port,
    host_port             = var.port,
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

  ingress {
    description = "Allow traffic from internal ALB of GP2GP Messenger"
    protocol    = "tcp"
    from_port   = "3000"
    to_port     = "3000"
    security_groups = [
      aws_security_group.gp2gp_messenger_alb.id
    ]
  }

  egress {
    description = "Allow All TCP Outbound"
    protocol    = "tcp"
    from_port   = 0
    to_port     = 65535
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-${var.component_name}-ecs-tasks-sg"
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}

resource "aws_security_group" "vpn_to_gp2gp_messenger_ecs" {
  count       = var.allow_vpn_to_ecs_tasks ? 1 : 0
  name        = "${var.environment}-vpn-to-${var.component_name}-ecs"
  description = "controls access from vpn to gp2gp messenger ecs task"
  vpc_id      = data.aws_ssm_parameter.deductions_private_vpc_id.value

  ingress {
    description     = "Allow vpn to access GP2GP Messenger ECS"
    protocol        = "tcp"
    from_port       = 3000
    to_port         = 3000
    security_groups = [data.aws_ssm_parameter.vpn_sg_id.value]
  }

  tags = {
    Name        = "${var.environment}-vpn-to-${var.component_name}-ecs"
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}

data "aws_ssm_parameter" "service_to_ehr_repo_sg_id" {
  name = "/repo/${var.environment}/output/prm-deductions-ehr-repository/service-to-ehr-repo-sg-id"
}

resource "aws_security_group_rule" "gp2gp_messenger_to_ehr_repo" {
  type                     = "ingress"
  protocol                 = "TCP"
  from_port                = 443
  to_port                  = 443
  security_group_id        = data.aws_ssm_parameter.service_to_ehr_repo_sg_id.value
  source_security_group_id = aws_security_group.ecs-tasks-sg.id
}

data "aws_ssm_parameter" "service-to-mhs-outbound-sg-id" {
  name = "/repo/${var.environment}/output/prm-mhs-infra/service-to-repo-mhs-outbound-sg-id"
}

resource "aws_security_group_rule" "gp2gp_messenger_to_mhs_outbound" {
  type                     = "ingress"
  protocol                 = "TCP"
  from_port                = 443
  to_port                  = 443
  security_group_id        = data.aws_ssm_parameter.service-to-mhs-outbound-sg-id.value
  source_security_group_id = aws_security_group.ecs-tasks-sg.id
}

data "aws_ssm_parameter" "pds_asid" {
  name = "/repo/${var.environment}/user-input/external/pds-asid"
}