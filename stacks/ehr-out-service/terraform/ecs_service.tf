locals {
  ecs_cluster_id  = aws_ecs_cluster.ecs_cluster.id
  ecs_task_sg_id  = aws_security_group.ecs_tasks_sg.id
  ecs_task_sg_ids = var.allow_vpn_to_ecs_tasks ? [aws_security_group.ecs_tasks_sg.id, aws_security_group.vpn_to_service_ecs[0].id] : [aws_security_group.ecs_tasks_sg.id]
  private_subnets = split(",", data.aws_ssm_parameter.deductions_private_private_subnets.value)
  int_alb_tg_arn  = aws_alb_target_group.internal_alb_tg.arn
}

resource "aws_ecs_service" "ecs_service" {
  name            = "${var.environment}-${var.component_name}"
  cluster         = local.ecs_cluster_id
  task_definition = aws_ecs_task_definition.task.arn
  desired_count   = var.service_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    security_groups = local.ecs_task_sg_ids
    subnets         = local.private_subnets
  }

  load_balancer {
    target_group_arn = local.int_alb_tg_arn
    container_name   = "${var.component_name}-container"
    container_port   = var.port
  }

  depends_on = [
    aws_alb_target_group.internal_alb_tg,
    aws_alb_listener_rule.int_alb_http_listener_rule,
    aws_alb_listener_rule.int_alb_https_listener_rule
  ]
}

resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${var.environment}-${var.component_name}"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}
