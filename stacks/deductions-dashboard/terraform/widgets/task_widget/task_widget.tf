variable "component" {
  validation {
    condition     = alltrue([contains(keys(var.component), "name"), contains(keys(var.component), "title")])
    error_message = "The component must have \"name\", and \"title\" keys."
  }
}

variable "metric_type" {
  validation {
    condition     = contains(["memory", "cpu"], var.metric_type)
    error_message = "The metric_type value must be \"memory\" or \"cpu\"."
  }
}

variable "environment" {
}

variable "region" {
  default = "eu-west-2"
}

locals {
  titles = {
    cpu = "CPU"
    memory = "Memory"
  }
  container_insights_log_group = "/aws/ecs/containerinsights/${var.environment}-${var.component.name}-ecs-cluster/performance"

  log_query = <<EOF
fields
  ${title(var.metric_type)}Utilized / ${title(var.metric_type)}Reserved * 100 as Percent,
  (AvailabilityZone like "${var.region}a") as is_A,
  (AvailabilityZone like "${var.region}b") as is_B,
  (AvailabilityZone like "${var.region}c") as is_C
| filter
    (Type = "Task")
| stats
    max(Percent * is_A) as A,
    max(Percent * is_B) as B,
    max(Percent * is_C) as C
    by bin(2m) as period
| sort
    period desc
EOF

  widget = {
    type = "log"
    properties = {
      query  = "SOURCE '${local.container_insights_log_group}' | ${local.log_query}"
      region = var.region
      title  = "${var.component.title} ${local.titles[var.metric_type]} %"
      view   = "timeSeries"
      yAxis = {
        left = {
          showUnits = false
        }
        right = {
          showUnits = false
        }
      }
    }
  }
}

output "widget" {
  value = local.widget
}