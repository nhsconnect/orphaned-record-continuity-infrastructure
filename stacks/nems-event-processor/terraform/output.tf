resource "aws_ssm_parameter" "incoming_nems_events_queue" {
  name  = "/repo/${var.environment}/output/${var.component_name}/incoming-nems-events-queue-name"
  type  = "String"
  value = aws_sqs_queue.incoming_nems_events.name
}

resource "aws_ssm_parameter" "unhandled_events_queue_name" {
  name  = "/repo/${var.environment}/output/${var.component_name}/unhandled_events_queue_name"
  type  = "String"
  value = aws_sqs_queue.unhandled_events.name
}

resource "aws_ssm_parameter" "suspensions_sns_topic" {
  name  = "/repo/${var.environment}/output/${var.component_name}/suspensions-sns-topic-arn"
  type  = "String"
  value = aws_sns_topic.suspensions.arn
}

resource "aws_ssm_parameter" "suspensions_observability_queue" {
  name  = "/repo/${var.environment}/output/${var.component_name}/suspensions-observability-queue-name"
  type  = "String"
  value = aws_sqs_queue.suspensions_observability.name
}

resource "aws_ssm_parameter" "dlq_sns_topic" {
  name  = "/repo/${var.environment}/output/${var.component_name}/dlq-sns-topic-arn"
  type  = "String"
  value = aws_sns_topic.dlq.arn
}

resource "aws_ssm_parameter" "dlq_name" {
  name  = "/repo/${var.environment}/output/${var.component_name}/dlq-name"
  type  = "String"
  value = aws_sqs_queue.dlq.name
}

resource "aws_ssm_parameter" "ecs-cluster-name" {
  name  = "/repo/${var.environment}/output/${var.component_name}/nems-event-processor-ecs-cluster-name"
  type  = "String"
  value = aws_ecs_cluster.ecs-cluster.name
}

resource "aws_ssm_parameter" "re_registrations_sns_topic" {
  name  = "/repo/${var.environment}/output/${var.component_name}/re-registrations-sns-topic-arn"
  type  = "String"
  value = aws_sns_topic.re_registrations_topic.arn
}