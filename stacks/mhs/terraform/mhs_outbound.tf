locals {
  outbound_alb_sgs = var.allow_vpn_to_mhs_outbound_lb ? [
    aws_security_group.mhs_outbound_alb.id,
    aws_security_group.alb_to_mhs_outbound_ecs.id,
    aws_security_group.service_to_mhs_outbound.id,
    aws_security_group.vpn_to_mhs_outbound.id,
    aws_security_group.gocd_to_mhs_outbound.id
    ] : [
    aws_security_group.mhs_outbound_alb.id,
    aws_security_group.alb_to_mhs_outbound_ecs.id,
    aws_security_group.service_to_mhs_outbound.id,
    aws_security_group.gocd_to_mhs_outbound.id
  ]
  ecs_task_sgs = var.allow_vpn_to_ecs_tasks ? [aws_security_group.outbound_ecs_tasks_sg.id, aws_security_group.vpn_to_mhs_outbound_ecs[0].id] : [aws_security_group.outbound_ecs_tasks_sg.id]
}

resource "aws_ecs_cluster" "mhs_outbound_cluster" {
  name = "${var.environment}-${var.cluster_name}-mhs-outbound-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name        = "${var.environment}-${var.cluster_name}-mhs-outbound"
    Environment = var.environment
    CreatedBy   = var.repo_name
  }
}

resource "aws_ecs_task_definition" "mhs_outbound_task" {
  family = "${var.environment}-${var.cluster_name}-mhs-outbound"
  container_definitions = jsonencode(
    [
      {
        name        = "mhs-outbound"
        image       = "nhsdev/nia-mhs-inbound:${var.build_id}"
        environment = local.mhs_outbound_base_environment_vars
        secrets     = local.mhs_outbound_base_secrets
        essential   = true
        logConfiguration = {
          logDriver = "awslogs"
          options = {
            awslogs-group         = aws_cloudwatch_log_group.mhs_outbound_log_group.name
            awslogs-region        = var.region
            awslogs-stream-prefix = var.build_id
          }
        }
        portMappings = [
          {
            containerPort = 80
            hostPort      = 80
            protocol      = "tcp"
          }
        ]
      }
    ]
  )
  cpu          = "512"
  memory       = "1024"
  network_mode = "awsvpc"
  requires_compatibilities = [
    "FARGATE"
  ]
  tags = {
    Name        = "${var.environment}-mhs-outbound-task"
    Environment = var.environment
    CreatedBy   = var.repo_name
  }
  task_role_arn      = local.task_role_arn
  execution_role_arn = local.execution_role_arn
}

resource "aws_ecs_service" "mhs_outbound_service" {
  name                               = "${var.environment}-${var.cluster_name}-mhs-outbound"
  cluster                            = aws_ecs_cluster.mhs_outbound_cluster.id
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
  desired_count                      = var.mhs_outbound_service_minimum_instance_count
  launch_type                        = "FARGATE"
  platform_version                   = "1.3.0"
  scheduling_strategy                = "REPLICA"
  task_definition                    = aws_ecs_task_definition.mhs_outbound_task.arn

  network_configuration {
    assign_public_ip = false
    security_groups  = local.ecs_task_sgs
    subnets          = local.mhs_private_subnet_ids
  }

  load_balancer {
    # In the MHS outbound task definition, we define only 1 container, and for that container, we expose only 1 port
    # That is why in these 2 lines below we do "[0]" to reference that one container and port definition.
    container_name   = jsondecode(aws_ecs_task_definition.mhs_outbound_task.container_definitions)[0].name
    container_port   = 80
    target_group_arn = aws_lb_target_group.outbound_alb_target_group.arn
  }

  depends_on = [
    aws_alb.outbound_alb
  ]

}

data "aws_ssm_parameter" "alb_access_logs_bucket" {
  name = "/repo/${var.environment}/output/prm-deductions-infra/alb-access-logs-s3-bucket-id"
}

resource "aws_alb" "outbound_alb" {
  name                       = "${var.environment}-${var.cluster_name}-mhs-out-alb"
  subnets                    = local.mhs_private_subnet_ids
  security_groups            = local.outbound_alb_sgs
  internal                   = true
  drop_invalid_header_fields = true
  enable_deletion_protection = true

  access_logs {
    bucket  = data.aws_ssm_parameter.alb_access_logs_bucket.value
    enabled = true
  }

  tags = {
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}

# Exists to be referred by the ECS task of mhs outbound
resource "aws_security_group" "mhs_outbound_alb" {
  name        = "${var.environment}-${var.cluster_name}-mhs-out-alb"
  description = "mhs outbound ALB security group"
  vpc_id      = local.mhs_vpc_id

  tags = {
    Name        = "${var.environment}-${var.cluster_name}-mhs-out-alb"
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}

resource "aws_security_group" "alb_to_mhs_outbound_ecs" {
  name        = "${var.environment}-${var.cluster_name}-alb-to-mhs-out-ecs"
  description = "Allows mhs outbound ALB connections to mhs outbound component task"
  vpc_id      = local.mhs_vpc_id

  egress {
    description     = "Allow outbound connections to mhs outbound ECS Task"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.outbound_ecs_tasks_sg.id]
  }

  tags = {
    Name        = "${var.environment}-${var.cluster_name}-alb-to-mhs-out-ecs"
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}

resource "aws_security_group" "outbound_ecs_tasks_sg" {
  name   = "${var.environment}-${var.cluster_name}-mhs-out-ecs-tasks-sg"
  vpc_id = local.mhs_vpc_id

  ingress {
    description     = "MHS outbound ingress from ALB"
    protocol        = "tcp"
    from_port       = 80
    to_port         = 80
    security_groups = [aws_security_group.mhs_outbound_alb.id]
  }

  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = [local.mhs_vpc_cidr_block]
    description = "MHS outbound egress to DNS"
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.spine_cidr]
    description = "MHS outbound egress to SDS and spine"
  }

  egress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    prefix_list_ids = [
      local.mhs_dynamodb_vpc_endpoint_prefix_list_id,
      local.mhs_s3_vpc_endpoint_prefix_list_id
    ]
    description = "MHS outbound egress to AWS VPC endpoints for dynamodb and s3 (gateway type)"
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [local.mhs_vpc_cidr_block]
    description = "MHS outbound egress to MHS VPC"
  }

  tags = {
    Name        = "${var.environment}-${var.cluster_name}-mhs-out-ecs-tasks-sg"
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}

resource "aws_security_group" "service_to_mhs_outbound" {
  name        = "${var.environment}-${var.cluster_name}-service-to-mhs-out"
  description = "controls access from repo services to MHS outbound"
  vpc_id      = local.mhs_vpc_id

  tags = {
    Name        = "${var.environment}-${var.cluster_name}-service-to-mhs-out"
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}

resource "aws_ssm_parameter" "service_to_mhs_outbound" {
  name  = "/repo/${var.environment}/output/${var.repo_name}/service-to-${var.cluster_name}-mhs-outbound-sg-id"
  type  = "String"
  value = aws_security_group.service_to_mhs_outbound.id
  tags = {
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}

resource "aws_security_group" "vpn_to_mhs_outbound" {
  name        = "${var.environment}-${var.cluster_name}-vpn-to-mhs-outbound-lb"
  description = "controls access from vpn to MHS outbound"
  vpc_id      = local.mhs_vpc_id

  ingress {
    description     = "Allow vpn to access mhs-outbound ALB"
    protocol        = "tcp"
    from_port       = 443
    to_port         = 443
    security_groups = [data.aws_ssm_parameter.vpn_sg_id.value]
  }

  tags = {
    Name        = "${var.environment}-${var.cluster_name}-vpn-to-mhs-outbound-lb"
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}

resource "aws_security_group" "gocd_to_mhs_outbound" {
  name        = "${var.environment}-${var.cluster_name}-gocd-to-mhs-outbound"
  description = "controls access from gocd to MHS outbound"
  vpc_id      = local.mhs_vpc_id

  ingress {
    description     = "Allow gocd to access mhs-outbound ALB"
    protocol        = "tcp"
    from_port       = 443
    to_port         = 443
    security_groups = [data.aws_ssm_parameter.gocd_sg_id.value]
  }

  tags = {
    Name        = "${var.environment}-${var.cluster_name}-gocd-to-mhs-outbound"
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}

resource "aws_security_group" "vpn_to_mhs_outbound_ecs" {
  count       = var.allow_vpn_to_ecs_tasks ? 1 : 0
  name        = "${var.environment}-${var.cluster_name}-vpn-to-mhs-outbound-ecs"
  description = "Controls access from vpn to mhs outbound ecs"
  vpc_id      = local.mhs_vpc_id

  ingress {
    from_port       = 3000
    protocol        = "tcp"
    to_port         = 3000
    security_groups = [data.aws_ssm_parameter.vpn_sg_id.value]
  }

  tags = {
    Name        = "${var.environment}-${var.cluster_name}-vpn-to-mhs-outbound-ecs"
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}

data "aws_ssm_parameter" "vpn_sg_id" {
  name = "/repo/${var.environment}/output/prm-deductions-infra/vpn-sg-id"
}

data "aws_ssm_parameter" "gocd_sg_id" {
  name = "/repo/${var.environment}/user-input/external/gocd-agent-sg-id"
}

resource "aws_lb_target_group" "outbound_alb_target_group" {
  name                 = "${var.environment}-${var.cluster_name}-mhs-outbound"
  port                 = 80
  protocol             = "HTTP"
  target_type          = "ip"
  vpc_id               = local.mhs_vpc_id
  deregistration_delay = var.deregistration_delay

  health_check {
    path    = "/healthcheck"
    matcher = "200"
  }

  tags = {
    Name        = "${var.environment}-mhs-outbound-alb-target-group"
    Environment = var.environment
    CreatedBy   = var.repo_name
  }
}

# Listener for MHS outbound service's load balancer that forwards requests to the correct target group
resource "aws_alb_listener" "outbound_alb_listener" {
  load_balancer_arn = aws_alb.outbound_alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-Ext-2018-06"
  certificate_arn   = aws_acm_certificate.mhs_outbound_cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.outbound_alb_target_group.arn
  }
}

resource "aws_route53_record" "mhs_outbound_load_balancer_record" {
  zone_id = data.aws_ssm_parameter.environment_private_zone_id.value
  name    = "outbound.${var.cluster_suffix}"
  type    = "A"

  alias {
    name                   = aws_alb.outbound_alb.dns_name
    zone_id                = aws_alb.outbound_alb.zone_id
    evaluate_target_health = false
  }

}

resource "aws_ssm_parameter" "outbound_url" {
  name  = "/repo/${var.environment}/output/${var.repo_name}/${var.cluster_name}-mhs-outbound-url"
  type  = "String"
  value = "https://${aws_route53_record.mhs_outbound_load_balancer_record.name}.${data.aws_route53_zone.environment_private_zone.name}"
  tags = {
    Environment = var.environment
    CreatedBy   = var.repo_name
  }
}

locals {
  mhs_spine_org_code = var.spine_org_code
  mhs_outbound_base_environment_vars = [
    {
      name  = "MHS_LOG_LEVEL"
      value = var.mhs_log_level
    },
    {
      name  = "MHS_STATE_TABLE_NAME"
      value = aws_dynamodb_table.mhs_state_table.name
    },
    {
      name  = "MHS_SYNC_ASYNC_STATE_TABLE_NAME"
      value = aws_dynamodb_table.mhs_sync_async_table.name
    },
    {
      name  = "MHS_RESYNC_RETRIES"
      value = var.mhs_resynchroniser_max_retries
    },
    {
      name  = "MHS_RESYNC_INTERVAL"
      value = var.mhs_resynchroniser_interval
    },
    {
      name  = "MHS_SPINE_ORG_CODE"
      value = local.mhs_spine_org_code
    },
    {
      name  = "MHS_SPINE_REQUEST_MAX_SIZE"
      value = var.mhs_spine_request_max_size
    },
    {
      name  = "MHS_FORWARD_RELIABLE_ENDPOINT_URL"
      value = var.mhs_forward_reliable_endpoint_url
    },
    {
      name  = "MHS_SYNCHRONOUS_ENDPOINT_URL"
      value = var.mhs_synchronous_endpoint_url
    },
    {
      name  = "MHS_ASYNCHRONOUS_RELIABLE_ENDPOINT_URL"
      value = var.mhs_asynchronous_reliable_endpoint_url
    },
    {
      name  = "MHS_OUTBOUND_ROUTING_LOOKUP_METHOD"
      value = var.mhs_outbound_lookup_method
    },
    {
      name  = "MHS_SDS_API_URL"
      value = data.aws_ssm_parameter.sds_api_url.value
    },
    {
      name  = "SUPPORTED_FILE_TYPES"
      value = file("${path.root}/data/supported-ehr-attachment-types")
    }
  ]
  mhs_outbound_base_secrets = [
    {
      name      = "MHS_SECRET_PARTY_KEY"
      valueFrom = local.party_key_arn
    },
    {
      name      = "MHS_SECRET_CLIENT_CERT"
      valueFrom = local.client_cert_arn
    },
    {
      name      = "MHS_SECRET_CLIENT_KEY"
      valueFrom = local.client_key_arn
    },
    {
      name      = "MHS_SECRET_CA_CERTS"
      valueFrom = local.outbound_ca_certs_arn
    },
    {
      name      = "MHS_SDS_API_KEY"
      valueFrom = data.aws_ssm_parameter.sds_api_key.arn
    }
  ]
}

resource "aws_acm_certificate" "mhs_outbound_cert" {
  domain_name = "outbound.${var.cluster_suffix}.${data.aws_route53_zone.environment_public_zone.name}"

  validation_method = "DNS"

  tags = {
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}

resource "aws_route53_record" "mhs_outbound_cert_validation_record" {
  for_each = {
    for dvo in aws_acm_certificate.mhs_outbound_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_ssm_parameter.environment_public_zone_id.value
}

resource "aws_acm_certificate_validation" "mhs_outbound_cert_validation" {
  certificate_arn         = aws_acm_certificate.mhs_outbound_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.mhs_outbound_cert_validation_record : record.fqdn]
}

data "aws_ssm_parameter" "sds_api_url" {
  name = "/repo/${var.environment}/user-input/external/sds-fhir-url"
}

data "aws_ssm_parameter" "sds_api_key" {
  name = "/repo/${var.environment}/user-input/external/sds-fhir-api-key"
}
