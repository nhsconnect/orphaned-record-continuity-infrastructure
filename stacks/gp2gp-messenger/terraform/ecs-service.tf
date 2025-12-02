locals {
  ecs_cluster_id  = aws_ecs_cluster.ecs-cluster.id
  ecs_task_sg_ids = var.allow_vpn_to_ecs_tasks ? [aws_security_group.ecs-tasks-sg.id, aws_security_group.vpn_to_gp2gp_messenger_ecs[0].id] : [aws_security_group.ecs-tasks-sg.id]
  private_subnets = split(",", data.aws_ssm_parameter.deductions_private_private_subnets.value)
  # alb_tg_arn        = aws_alb_target_group.alb-tg.arn
  int_alb_tg_arn = aws_alb_target_group.internal-alb-tg.arn
}

resource "aws_ecs_service" "ecs-service" {
  name            = "${var.environment}-${var.component_name}-service"
  cluster         = local.ecs_cluster_id
  task_definition = aws_ecs_task_definition.task.arn
  desired_count   = var.service_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    security_groups = local.ecs_task_sg_ids
    subnets         = local.private_subnets
  }

  # load_balancer {
  #   target_group_arn = local.alb_tg_arn
  #   container_name   = "${var.component_name}-container"
  #   container_port   = var.port
  # }

  load_balancer {
    target_group_arn = local.int_alb_tg_arn
    container_name   = "${var.component_name}-container"
    container_port   = var.port
  }

  depends_on = [
    # aws_alb_target_group.alb-tg,
    aws_alb_target_group.internal-alb-tg,
    # aws_alb_listener_rule.alb-http-listener-rule,
    aws_alb_listener_rule.int-alb-http-listener-rule,
    # aws_alb_listener_rule.alb-https-listener-rule,
    aws_alb_listener_rule.int-alb-https-listener-rule
  ]

  # tags = {
  #   Terraform = "true"
  #   Environment = var.environment
  #   Deductions-Component = var.component_name
  #   TurnOffAtNight = "True"
  # }
}

resource "aws_ecs_cluster" "ecs-cluster" {
  name = "${var.environment}-${var.component_name}-ecs-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}
