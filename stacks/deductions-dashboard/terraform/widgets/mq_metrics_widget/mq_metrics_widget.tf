variable "component" {
  validation {
    condition     = alltrue([contains(keys(var.component), "name"), contains(keys(var.component), "title"), contains(keys(var.component), "broker")])
    error_message = "The component must have \"name\", \"broker\" and \"title\" keys."
  }
}

variable "environment" {
}

variable "region" {
  default = "eu-west-2"
}

locals {
  widget = {
    type = "metric"
    properties = {
      metrics = [
        ["AWS/AmazonMQ", "EnqueueCount", "Broker", "${var.component.broker}","Queue", "${var.component.name}"],
        [".", "InFlightCount", ".", ".", ".", "."],
        [".", "DequeueCount", ".", ".", ".", "."],
        [".", "ConsumerCount", ".", ".", ".", "."],
        [".", "MemoryUsage", ".", ".", ".", "."],
        [".", "CpuUtilization", ".", "."]
      ],
      region = var.region
      title  = "${var.component.title}"
      view   = "timeSeries"
      stat   = "Average"
      yAxis  = {
        right = {
          label = "Size"
        }
      }
    }
  }
}

output "widget" {
  value = local.widget
}
