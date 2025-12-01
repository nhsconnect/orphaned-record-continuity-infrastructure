locals {
  domain = trimsuffix("${var.dns_name}.${data.aws_route53_zone.environment_public_zone.name}", ".")
}

data "aws_ssm_parameter" "alb_access_logs_bucket" {
  name = "/repo/${var.environment}/output/prm-deductions-infra/alb-access-logs-s3-bucket-id"
}

resource "aws_alb" "alb-internal" {
  name    = "${var.environment}-${var.component_name}-alb-int"
  subnets = local.private_subnets
  security_groups = [
    aws_security_group.pds_adaptor_alb.id,
    aws_security_group.alb_to_pds_adaptor_ecs.id,
    aws_security_group.service_to_pds_adaptor.id,
    aws_security_group.gocd_to_pds_adaptor.id,
    aws_security_group.vpn_to_pds_adaptor.id,
  ]
  internal                   = true
  drop_invalid_header_fields = true
  idle_timeout               = 300
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

resource "aws_security_group" "pds_adaptor_alb" {
  name        = "${var.environment}-alb-${var.component_name}"
  description = "pds-adaptor ALB security group"
  vpc_id      = data.aws_ssm_parameter.deductions_private_vpc_id.value

  ingress {
    description = "Allow traffic from clients to ALB"
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    security_groups = [
      data.aws_ssm_parameter.suspension-service-ecs-sg-id.value,
      data.aws_ssm_parameter.end-for-transfer-service-ecs-sg-id.value,
      data.aws_ssm_parameter.re-registration-ecs-sg-id.value
    ]
  }

  tags = {
    Name        = "${var.environment}-alb-${var.component_name}"
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}

resource "aws_alb_listener" "int-alb-listener-http" {
  load_balancer_arn = aws_alb.alb-internal.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Error"
      status_code  = "501"
    }
  }
}

resource "aws_alb_listener" "int-alb-listener-https" {
  load_balancer_arn = aws_alb.alb-internal.arn
  port              = "443"
  protocol          = "HTTPS"

  ssl_policy      = "ELBSecurityPolicy-TLS-1-2-Ext-2018-06"
  certificate_arn = aws_acm_certificate_validation.pds_adaptor_cert_validation.certificate_arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Error"
      status_code  = "501"
    }
  }
}


resource "aws_alb_target_group" "internal-alb-tg" {
  name                 = "${var.environment}-${var.component_name}-int-tg"
  port                 = 8080
  protocol             = "HTTP"
  vpc_id               = data.aws_ssm_parameter.deductions_private_vpc_id.value
  target_type          = "ip"
  deregistration_delay = var.alb_deregistration_delay
  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 5
    timeout             = 5
    interval            = 30
    path                = "/actuator/health"
    port                = 8080
  }

  tags = {
    Environment = var.environment
    CreatedBy   = var.repo_name
  }
}

resource "aws_alb_listener_rule" "int-alb-http-listener-rule" {
  listener_arn = aws_alb_listener.int-alb-listener-http.arn
  priority     = 200

  action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  condition {
    host_header {
      values = [local.domain]
    }
  }
}

resource "aws_alb_listener_rule" "int-alb-https-listener-rule" {
  listener_arn = aws_alb_listener.int-alb-listener-https.arn
  priority     = 201

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.internal-alb-tg.arn
  }

  condition {
    host_header {
      values = [local.domain]
    }
  }
}

resource "aws_lb_listener_certificate" "pds-adaptor-int-listener-cert" {
  listener_arn    = aws_alb_listener.int-alb-listener-https.arn
  certificate_arn = aws_acm_certificate_validation.pds_adaptor_cert_validation.certificate_arn
}

resource "aws_security_group" "alb_to_pds_adaptor_ecs" {
  name        = "${var.environment}-alb-to-${var.component_name}-ecr"
  description = "Allows pds adaptor ALB connections to pds-adaptor component task"
  vpc_id      = data.aws_ssm_parameter.deductions_private_vpc_id.value

  egress {
    description     = "Allow outbound connections to pds-adaptor ECS Task"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [local.ecs_task_sg_id]
  }

  tags = {
    Name        = "${var.environment}-alb-to-${var.component_name}-ecs"
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}

resource "aws_security_group" "service_to_pds_adaptor" {
  name        = "${var.environment}-service-to-${var.component_name}"
  description = "Controls access from repo services to pds-adaptor"
  vpc_id      = data.aws_ssm_parameter.deductions_private_vpc_id.value

  tags = {
    Name        = "${var.environment}-service-to-${var.component_name}-sg"
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}

resource "aws_ssm_parameter" "service_to_pds_adaptor" {
  name  = "/repo/${var.environment}/output/prm-deductions-infra/service-to-pds-adaptor-sg-id"
  type  = "String"
  value = aws_security_group.service_to_pds_adaptor.id
  tags = {
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}

resource "aws_security_group" "vpn_to_pds_adaptor" {
  name        = "${var.environment}-vpn-to-${var.component_name}"
  description = "Controls access from vpn to pds-adaptor"
  vpc_id      = data.aws_ssm_parameter.deductions_private_vpc_id.value

  tags = {
    Name        = "${var.environment}-vpn-to-${var.component_name}-sg"
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}

resource "aws_security_group_rule" "vpn_to_pds_adaptor" {
  count                    = var.grant_access_through_vpn ? 1 : 0
  type                     = "ingress"
  description              = "Allow vpn to access PDS Adaptor ALB"
  protocol                 = "tcp"
  from_port                = 443
  to_port                  = 443
  source_security_group_id = data.aws_ssm_parameter.vpn_sg_id.value
  security_group_id        = aws_security_group.vpn_to_pds_adaptor.id
}
resource "aws_security_group" "gocd_to_pds_adaptor" {
  name        = "${var.environment}-gocd-to-${var.component_name}"
  description = "Controls access from gocd to pds-adaptor"
  vpc_id      = data.aws_ssm_parameter.deductions_private_vpc_id.value

  ingress {
    description = "Allow gocd to access pds-adaptor ALB"
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    security_groups = [data.aws_ssm_parameter.gocd_sg_id.value]
  }

  tags = {
    Name = "${var.environment}-gocd-to-${var.component_name}-sg"
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