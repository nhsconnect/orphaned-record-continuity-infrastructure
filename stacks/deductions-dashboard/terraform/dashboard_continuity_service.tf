data "aws_lb" "pds_adaptor_load_balancer" {
  name = "${var.environment}-pds-adaptor-alb-int"
}

data "aws_lb_target_group" "pds_adaptor_target_group" {
  name = "${var.environment}-pds-adaptor-int-tg"
}

locals {
  all_widgets = concat([
    {
      type       = "metric"
      properties = {
        metrics = [
          ["MeshForwarder", "MeshInboxMessageCount"]
        ],
        region  = var.region
        title   = "MESH Inbox Message Count"
        view    = "timeSeries"
        stat    = "Average"
        yAxis   = {
          left  = {
            showUnits = false
          }
          right = {
            showUnits = false
          }
        }
      }
    }
  ],
  values(module.queue_metrics_widgets).*.widget,
  values(module.error_count_widgets).*.widget,
  [module.health_lb_widgets["mesh"].widget],
  [module.health_widgets["nems"].widget],
  [module.health_lb_widgets["pds_adaptor"].widget],
  [module.health_widgets["suspensions"].widget],
  values(module.task_widgets).*.widget
  )

  queue_widget_definitions = [
    {
      name  = "${var.environment}-nems-event-processor-incoming"
      title = "NEMS Event Processor Incoming Queue"
    },
    {
      name  = "${var.environment}-nems-event-processor-suspensions-observability"
      title = "NEMS Processor Suspensions Observability Queue"
    },
    {
      name  = "${var.environment}-suspension-service-suspensions"
      title = "Suspension Service Incoming Queue"
    },
    {
      name  = "${var.environment}-mesh-forwarder-nems-events-observability"
      title = "MESH Forwarder Observability Queue"
    },
    {
      name  = "${var.environment}-nems-event-processor-unhandled-events"
      title = "NEMS Event Processor Unhandled Queue"
    },
    {
      name  = "${var.environment}-nems-event-processor-dlq"
      title = "NEMS Event Processor DLQ"
    },
    {
      name  = "${var.environment}-suspension-service-not-suspended-observability"
      title = "Suspension Service Not Suspended Observability Queue"
    },
    {
      name  = "${var.environment}-suspension-service-mof-updated"
      title = "Suspension Service MOF Updated Queue"
    }
  ]
  mesh                     = {
    name         = "mesh-forwarder"
    title        = "MESH Forwarder"
    loadbalancer = "NA"
    targetgroup  = "NA"
  }
  # to be completed (removing NA) when health metrics will be available on load balancer (like PDS adaptor below)
  mesh_na                  = {
    name         = "mesh-forwarder-na"
    title        = "(NA) MESH Forwarder"
    loadbalancer = "NA"
    targetgroup  = "NA"
  }

  nems = {
    name  = "nems-event-processor"
    title = "NEMS Event Processor"
  }

  pds_adaptor = {
    name         = "pds-adaptor"
    title        = "PDS Adaptor"
    loadbalancer = data.aws_lb.pds_adaptor_load_balancer.arn_suffix
    targetgroup  = data.aws_lb_target_group.pds_adaptor_target_group.arn_suffix
  }

  suspension_service = {
    name  = "suspension-service"
    title = "Suspension Service"
  }

  task_widget_components  = [
    local.mesh, local.nems, local.pds_adaptor, local.suspension_service
  ]
  task_widget_types       = ["cpu", "memory"]
  task_widget_definitions = [
    for pair in setproduct(local.task_widget_types, local.task_widget_components) : {
      component = pair[1]
      type      = pair[0]
    }
  ]
}

module "task_widgets" {
  for_each    = {
    for i, def in local.task_widget_definitions : i => def
  }
  source      = "./widgets/task_widget"
  environment = var.environment
  component   = each.value.component
  metric_type = each.value.type
}

module "error_count_widgets" {
  for_each  = {
    nems        = local.nems
    mesh        = local.mesh
    pds_adaptor = local.pds_adaptor
    suspensions = local.suspension_service
  }
  source    = "./widgets/error_count_widget"
  component = each.value
}

module "health_widgets" {
  for_each    = {
    nems        = local.nems
    suspensions = local.suspension_service
  }
  source      = "./widgets/health_widget"
  component   = each.value
  environment = var.environment
}

module "health_lb_widgets" {
  for_each    = {
    mesh        = local.mesh_na
    pds_adaptor = local.pds_adaptor
  }
  source      = "./widgets/health_lb_widget"
  component   = each.value
  environment = var.environment
}

module "queue_metrics_widgets" {
  for_each    = {
  for i, def in local.queue_widget_definitions : i => def
  }
  source      = "./widgets/queue_metrics_widget"
  component   = each.value
  environment = var.environment
}

resource "aws_cloudwatch_dashboard" "continuity_dashboard" {
  dashboard_body = jsonencode({
    widgets = local.all_widgets
  })
  dashboard_name = "ContinuityDashboard${title(var.environment)}"
}
