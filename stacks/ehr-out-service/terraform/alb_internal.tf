locals {
  domain = trimsuffix("${var.component_name}.${data.aws_route53_zone.environment_public_zone.name}", ".")
}

resource "aws_alb" "alb_internal" {
  name    = "${var.environment}-${var.component_name}-alb-int"
  subnets = local.private_subnets
  security_groups = [
    aws_security_group.service_from_alb.id,
    aws_security_group.alb_to_app_ecs.id,
    aws_security_group.vpn_to_service_alb.id,
  ]
  internal                   = true
  drop_invalid_header_fields = true
  enable_deletion_protection = true

  tags = {
    CreatedBy   = var.repo_name
    Environment = var.environment
  }

  access_logs {
    bucket  = data.aws_ssm_parameter.alb_access_logs_bucket.value
    enabled = true
    prefix  = "alb_internal"
  }

}

resource "aws_security_group" "service_from_alb" {
  name        = "${var.environment}-alb-${var.component_name}"
  description = "Service from ALB security group"
  vpc_id      = data.aws_ssm_parameter.deductions_private_vpc_id.value

  tags = {
    Name        = "${var.environment}-alb-${var.component_name}"
    CreatedBy   = var.repo_name
    Environment = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_alb_listener" "int_alb_listener_http" {
  load_balancer_arn = aws_alb.alb_internal.arn
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

resource "aws_alb_listener" "int_alb_listener_https" {
  load_balancer_arn = aws_alb.alb_internal.arn
  port              = "443"
  protocol          = "HTTPS"

  ssl_policy      = "ELBSecurityPolicy-TLS-1-2-Ext-2018-06"
  certificate_arn = aws_acm_certificate_validation.service_cert_validation.certificate_arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Error"
      status_code  = "501"
    }
  }
}


resource "aws_alb_target_group" "internal_alb_tg" {
  name                 = "${var.environment}-${var.component_name}-int-tg"
  port                 = 3000
  protocol             = "HTTP"
  vpc_id               = data.aws_ssm_parameter.deductions_private_vpc_id.value
  target_type          = "ip"
  deregistration_delay = var.alb_deregistration_delay
  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 5
    timeout             = 5
    interval            = 10
    path                = "/health"
    port                = 3000
  }

  tags = {
    Environment = var.environment
    CreatedBy   = var.repo_name
  }
}

resource "aws_alb_listener_rule" "int_alb_http_listener_rule" {
  listener_arn = aws_alb_listener.int_alb_listener_http.arn
  priority     = 300

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
      values = [
        local.domain
      ]
    }
  }
}

resource "aws_alb_listener_rule" "int_alb_https_listener_rule" {
  listener_arn = aws_alb_listener.int_alb_listener_https.arn
  priority     = 301

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.internal_alb_tg.arn
  }

  condition {
    host_header {
      values = [
        local.domain
      ]
    }
  }
}

resource "aws_lb_listener_certificate" "app_internal_listener_cert" {
  listener_arn    = aws_alb_listener.int_alb_listener_https.arn
  certificate_arn = aws_acm_certificate_validation.service_cert_validation.certificate_arn
}

resource "aws_security_group" "alb_to_app_ecs" {
  name        = "${var.environment}-alb-to-${var.component_name}-ecs"
  description = "Allows ALB connections to service task"
  vpc_id      = data.aws_ssm_parameter.deductions_private_vpc_id.value

  egress {
    description     = "Allow outbound connections from ECS Task"
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

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "vpn_to_service_alb" {
  name        = "${var.environment}-vpn-to-${var.component_name}"
  description = "Controls access from vpn to service"
  vpc_id      = data.aws_ssm_parameter.deductions_private_vpc_id.value

  tags = {
    Name        = "${var.environment}-vpn-to-${var.component_name}-sg"
    CreatedBy   = var.repo_name
    Environment = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "vpn_to_service_alb" {
  count                    = var.grant_access_through_vpn ? 1 : 0
  type                     = "ingress"
  description              = "Allow vpn to access service ALB"
  protocol                 = "tcp"
  from_port                = 443
  to_port                  = 443
  source_security_group_id = data.aws_ssm_parameter.vpn_sg_id.value
  security_group_id        = aws_security_group.vpn_to_service_alb.id
}

resource "aws_cloudwatch_metric_alarm" "alb_http_errors" {
  alarm_name          = "${var.repo_name} 5xx errors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "This metric monitors number of 5xx http status codes associated with ${var.repo_name}"
  treat_missing_data  = "notBreaching"
  dimensions = {
    LoadBalancer = aws_alb.alb_internal.arn_suffix
  }
}
