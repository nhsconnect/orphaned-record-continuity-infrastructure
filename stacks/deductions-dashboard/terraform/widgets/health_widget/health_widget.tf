variable "component" {
  validation {
    condition     = alltrue([contains(keys(var.component), "name"), contains(keys(var.component), "title")])
    error_message = "The component must have \"name\" and \"title\" keys."
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
        [ local.component_pascal_case, "Health", "Environment", var.environment ]
      ]
      region = var.region
      title = "${var.component.title} Health"
      view = "timeSeries"
      stat = "Average"
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