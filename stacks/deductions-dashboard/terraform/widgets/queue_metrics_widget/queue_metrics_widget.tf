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
        ["AWS/SQS", "NumberOfMessagesReceived", "QueueName", "${var.component.name}"],
        [".", "NumberOfMessagesSent", ".", "."],
        [".", "ApproximateAgeOfOldestMessage", ".", "."],
        [".", "ApproximateNumberOfMessagesVisible", ".", "."],
        [".", "SentMessageSize", ".", ".", { "yAxis": "right" } ]
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