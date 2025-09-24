variable "component" {
  validation {
    condition     = alltrue([contains(keys(var.component), "name"), contains(keys(var.component), "title")])
    error_message = "The component must have \"name\" and \"title\" keys."
  }
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
        [local.component_pascal_case, "ErrorCountInLogs"]
      ],
      region = var.region
      title  = "${var.component.title} Error Count"
      view   = "timeSeries"
      stat   = "Sum"
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