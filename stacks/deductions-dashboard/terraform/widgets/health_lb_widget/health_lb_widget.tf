variable "component" {
  validation {
    condition = alltrue([
      contains(keys(var.component), "name"),
      contains(keys(var.component), "title"),
      contains(keys(var.component), "loadbalancer"),
      contains(keys(var.component), "targetgroup")
    ])
    error_message = "The component must have \"name\", \"title\", \"loadbalancer\", and \"targetgroup\" keys."
  }
}

variable "environment" {
}

variable "region" {
  default = "eu-west-2"
}

locals {
  component_pascal_case = replace(title(var.component.name), "-", "")

  widget = {
    type = "metric"
    properties = {
      metrics = [
        ["AWS/ApplicationELB", "HealthyHostCount", "TargetGroup", "${var.component.targetgroup}", "LoadBalancer", "${var.component.loadbalancer}"],
        [".", "UnHealthyHostCount", ".", ".", ".", "."]
      ]
      region = var.region
      title  = "${var.component.title} Health"
      view   = "timeSeries"
      stat   = "Average"
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