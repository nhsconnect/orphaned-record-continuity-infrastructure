locals {
  suspension_service_metric_namespace = "SuspensionService"
  sqs_namespace                       = "AWS/SQS"
}


resource "aws_cloudwatch_metric_alarm" "suspension_service_scale_up_alarm" {
  alarm_name          = "${var.environment}-${var.component_name}-scale-up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  threshold           = "10"
  alarm_description   = "Scale up alarm for suspension-service"
  actions_enabled     = true
  alarm_actions       = [aws_appautoscaling_policy.scale_up.arn]

  metric_query {
    id          = "e1"
    expression  = "IF (${var.scale_up_expression})"
    label       = "Expression"
    return_data = "true"
  }

  metric_query {
    id = "m1"

    metric {
      metric_name = "NumberOfMessagesReceived"
      namespace   = local.sqs_namespace
      period      = "180"
      stat        = "Sum"
      unit        = "Count"

      dimensions = {
        QueueName = aws_sqs_queue.suspensions.name
      }
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "suspension_service_scale_down_alarm" {
  alarm_name          = "${var.environment}-${var.component_name}-scale-down"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = var.scale_down_number_of_empty_receives_count * var.core_task_number
  evaluation_periods  = "1"
  metric_name         = "NumberOfEmptyReceives"
  namespace           = local.sqs_namespace
  alarm_description   = "Alarm to alert when all events are processed in the queue"
  statistic           = "Sum"
  period              = 300
  dimensions = {
    QueueName = aws_sqs_queue.suspensions.name
  }
  treat_missing_data = "notBreaching"
  actions_enabled    = var.enable_scale_action
  alarm_actions      = [aws_appautoscaling_policy.scale_down.arn]
}

resource "aws_appautoscaling_policy" "scale_down" {
  name               = "scale-down"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Maximum"

    step_adjustment {
      scaling_adjustment          = -1
      metric_interval_lower_bound = 0
    }
  }
}

resource "aws_appautoscaling_policy" "scale_up" {
  name               = "scale-up"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Maximum"

    step_adjustment {
      scaling_adjustment          = 1
      metric_interval_lower_bound = 0
    }
  }
}

resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = 1
  min_capacity       = 0
  resource_id        = "service/${var.ecs_cluster_name}/${var.ecs_service_name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_cloudwatch_metric_alarm" "suspensions_queue_age_of_message" {
  alarm_name          = "${var.environment}-${var.component_name}-queue-age-of-message"
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.threshold_for_suspensions_queue_age_of_message
  evaluation_periods  = "1"
  metric_name         = "ApproximateAgeOfOldestMessage"
  namespace           = local.sqs_namespace
  alarm_description   = "Alarm to alert approximate time for message in the queue"
  statistic           = "Maximum"
  period              = var.period_of_age_of_message_metric
  dimensions = {
    QueueName = aws_sqs_queue.suspensions.name
  }
  alarm_actions = [data.aws_sns_topic.alarm_notifications.arn]
  ok_actions    = [data.aws_sns_topic.alarm_notifications.arn]
}

data "aws_sns_topic" "alarm_notifications" {
  name = "${var.environment}-alarm-notifications-sns-topic"
}
