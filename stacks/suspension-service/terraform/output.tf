resource "aws_ssm_parameter" "mof_updated_queue" {
  name  = "/repo/${var.environment}/output/${var.component_name}/mof-updated-queue-name"
  type  = "String"
  value = aws_sqs_queue.mof_updated.name
}

resource "aws_ssm_parameter" "ecs_tasks_sg" {
  name  = "/repo/${var.environment}/output/${var.component_name}/ecs-sg-id"
  type  = "String"
  value = aws_security_group.ecs-tasks-sg.id
}

resource "aws_ssm_parameter" "ecs-cluster-name" {
  name  = "/repo/${var.environment}/output/${var.component_name}/suspension-service-ecs-cluster-name"
  type  = "String"
  value = aws_ecs_cluster.ecs-cluster.name
}

output "process_only_synthetic_patients_value" {
  value = "process_only_synthetic_patients in set to: ${var.process_only_synthetic_patients}"
}

resource "aws_ssm_parameter" "active_suspensions_topic" {
  name  = "/repo/${var.environment}/output/${var.component_name}/active-suspensions-topic-arn"
  type  = "String"
  value = aws_sns_topic.active_suspensions.arn
}

resource "aws_ssm_parameter" "active_suspensions_kms_key_id" {
  name  = "/repo/${var.environment}/output/${var.component_name}/active-suspensions-kms-key-id"
  type  = "String"
  value = aws_kms_key.active_suspensions.id

  tags = {
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}