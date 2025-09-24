data "aws_lb" "gp2gp_messenger_load_balancer" {
  name = "${var.environment}-gp2gp-messenger-alb-int"
}

data "aws_lb_target_group" "gp2gp_messenger_target_group" {
  name = "${var.environment}-gp2gp-messenger-int-tg"
}

data "aws_lb" "ehr_repo_load_balancer" {
  name = "${var.environment}-ehr-repo-alb-int"
}

data "aws_lb_target_group" "ehr_repo_target_group" {
  name = "${var.environment}-ehr-repo-int-tg"
}

data "aws_lb" "mhs_inbound_load_balancer" {
  count = var.environment == "perf" ? 0 : 1
  name = "${var.environment}-repo-mhs-inbound"
}

data "aws_lb_target_group" "mhs_inbound_target_group" {
  count = var.environment == "perf" ? 0 : 1
  name = "${var.environment}-repo-mhs-in-https"
}

data "aws_lb" "mhs_outbound_load_balancer" {
  count = var.environment == "perf" ? 0 : 1
  name = "${var.environment}-repo-mhs-out-alb"
}

data "aws_lb_target_group" "mhs_outbound_target_group" {
  count = var.environment == "perf" ? 0 : 1
  name = "${var.environment}-repo-mhs-outbound"
}

locals {
  repo_all_widgets = concat(
    values(module.repo_queue_metrics_widgets).*.widget,
    values(module.repo_error_count_widgets).*.widget,
    values(module.repo_health_widgets).*.widget,
    values(module.repo_health_lb_widgets).*.widget,
    values(module.repo_task_widgets).*.widget,
    values(module.repo_mq_metrics_widgets).*.widget,
    values(module.repo_health_network_lb_widgets).*.widget
  )

  repo_mq_widget_definitions = [
    {
      name  = "inbound"
      broker = "deductor-amq-broker-${var.environment}-1"
      title = "Inbound MQueue"

    },
    {
      name  = "unhandled-messages"
      broker = "deductor-amq-broker-${var.environment}-1"
      title = "Unhandled MQueue"
    },
    {
      name  = "inbound"
      broker = "deductor-amq-broker-${var.environment}-2"
      title = "Inbound MQueue"

    },
    {
      name  = "unhandled-messages"
      broker = "deductor-amq-broker-${var.environment}-2"
      title = "Unhandled MQueue"
    }
  ]

  repo_queue_widget_definitions = [
    {
      name  = "${var.environment}-re-registration-service-re-registrations"
      title = "Re-registrations Queue"
    },
    {
      name  = "${var.environment}-ehr-transfer-service-negative-acknowledgments"
      title = "Negative Acknowledgements Queue"
    },
    {
      name  = "${var.environment}-ehr-transfer-service-negative-acknowledgments-observability"
      title = "Negative Acknowledgements Observability Queue"
    },
    {
      name  = "${var.environment}-ehr-transfer-service-small-ehr"
      title = "Small EHR Queue"
    },
    {
      name  = "${var.environment}-ehr-transfer-service-small-ehr-observability"
      title = "Small EHR Observability Queue"
    },
    {
      name  = "${var.environment}-ehr-transfer-service-large-ehr"
      title = "Large EHR Queue"
    },
    {
      name  = "${var.environment}-ehr-transfer-service-large-ehr-observability"
      title = "Large EHR Observability Queue"
    },
    {
      name  = "${var.environment}-ehr-transfer-service-large-message-fragments"
      title = "Large Message Fragments Queue"
    },
    {
      name  = "${var.environment}-ehr-transfer-service-large-message-fragments-observability"
      title = "Large Message Fragments Observability Queue"
    },
    {
      name  = "${var.environment}-ehr-transfer-service-positive-acknowledgements-observability"
      title = "Positive Acknowledgements Observability Queue"
    },
    {
      name  = "${var.environment}-ehr-transfer-service-ehr-complete"
      title = "EHR Complete Queue"
    },
    {
      name  = "${var.environment}-ehr-transfer-service-ehr-complete-observability"
      title = "EHR Complete Observability Queue"
    },
    {
      name  = "${var.environment}-end-of-transfer-service-transfer-complete"
      title = "Transfer Complete Queue"
    },
    {
      name  = "${var.environment}-end-of-transfer-service-transfer-complete-observability"
      title = "Transfer Complete Observability Queue"
    }
  ]

  re_registration_service = {
    name  = "re-registration-service"
    title = "Re-registration Service"
  }

  ehr_transfer_service = {
    name  = "ehr-transfer-service"
    title = "EHR Transfer Service"
  }

  end_of_transfer_service = {
    name  = "end-of-transfer-service"
    title = "End of Transfer Service"
  }

  ehr_repo = {
    name  = "ehr-repo"
    title = "EHR Repository Service"
    loadbalancer = var.environment == "perf" ? "NA" : data.aws_lb.ehr_repo_load_balancer.arn_suffix
    targetgroup  = var.environment == "perf" ? "NA" : data.aws_lb_target_group.ehr_repo_target_group.arn_suffix
  }

  gp2gp_messenger = {
    name  = "gp2gp-messenger"
    title = "GP2GP Messenger Service"
    loadbalancer = var.environment == "perf" ? "NA" : data.aws_lb.gp2gp_messenger_load_balancer.arn_suffix
    targetgroup  = var.environment == "perf" ? "NA" : data.aws_lb_target_group.gp2gp_messenger_target_group.arn_suffix
  }

  mhs_inbound = {
    name  = "mhs-inbound"
    title = "MHS Inbound Service"
    loadbalancer = var.environment == "perf" ? "NA" : data.aws_lb.mhs_inbound_load_balancer[0].arn_suffix
    targetgroup  = var.environment == "perf" ? "NA" : data.aws_lb_target_group.mhs_inbound_target_group[0].arn_suffix
  }

  mhs_outbound = {
    name  = "mhs-outbound"
    title = "MHS Outbound Service"
    loadbalancer = var.environment == "perf" ? "NA" : data.aws_lb.mhs_outbound_load_balancer[0].arn_suffix
    targetgroup  = var.environment == "perf" ? "NA" : data.aws_lb_target_group.mhs_outbound_target_group[0].arn_suffix
  }

  repo_task_widget_components  = [
    local.re_registration_service,
    local.ehr_transfer_service,
    local.end_of_transfer_service,
    local.ehr_repo,
    local.gp2gp_messenger,
    local.mhs_inbound,
    local.mhs_outbound
  ]
  repo_task_widget_types       = ["cpu", "memory"]
  repo_task_widget_definitions = [
  for pair in setproduct(local.repo_task_widget_types, local.repo_task_widget_components) : {
    component = pair[1]
    type      = pair[0]
  }
  ]
}

module "repo_task_widgets" {
  for_each    = {
  for i, def in local.repo_task_widget_definitions : i => def
  }
  source      = "./widgets/task_widget"
  environment = var.environment
  component   = each.value.component
  metric_type = each.value.type
}

module "repo_error_count_widgets" {
  for_each  = {
    re_registration_service = local.re_registration_service
    ehr_transfer_service = local.ehr_transfer_service
    end_of_transfer_service = local.end_of_transfer_service
    gp2gp_messenger = local.gp2gp_messenger
    ehr_repo = local.ehr_repo
    mhs_inbound = local.mhs_inbound
    mhs_outbound = local.mhs_outbound
  }
  source    = "./widgets/error_count_widget"
  component = each.value
}

module "repo_health_widgets" {
  for_each    = {
    re_registration_service = local.re_registration_service
    ehr_transfer_service = local.ehr_transfer_service
    end_of_transfer_service = local.end_of_transfer_service
  }
  source      = "./widgets/health_widget"
  component   = each.value
  environment = var.environment
}

module "repo_health_lb_widgets" {
  for_each    = {
    gp2gp_messenger = local.gp2gp_messenger
    ehr_repo = local.ehr_repo
    mhs_outbound = local.mhs_outbound
  }
  source      = "./widgets/health_lb_widget"
  component   = each.value
  environment = var.environment
}

module "repo_health_network_lb_widgets" {
  for_each    = {
    mhs_inbound = local.mhs_inbound
  }
  source      = "./widgets/health_network_lb_widget"
  component   = each.value
  environment = var.environment
}

module "repo_queue_metrics_widgets" {
  for_each    = {
  for i, def in local.repo_queue_widget_definitions : i => def
  }
  source      = "./widgets/queue_metrics_widget"
  component   = each.value
  environment = var.environment
}

module "repo_mq_metrics_widgets" {
  for_each    = {
  for i, def in local.repo_mq_widget_definitions : i => def
  }
  source      = "./widgets/mq_metrics_widget"
  component   = each.value
  environment = var.environment
}

resource "aws_cloudwatch_dashboard" "repository_dashboard" {
  dashboard_body = jsonencode({
    widgets = local.repo_all_widgets
  })
  dashboard_name = "RepositoryDashboard${title(var.environment)}"
}