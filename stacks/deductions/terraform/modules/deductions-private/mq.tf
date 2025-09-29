resource "aws_mq_broker" "deductor_mq_broker" {
  broker_name                = var.broker_name
  deployment_mode            = var.deployment_mode
  engine_type                = var.engine_type
  engine_version             = var.engine_version
  host_instance_type         = var.host_instance_type
  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  apply_immediately          = var.apply_immediately
  publicly_accessible        = "false"
  security_groups            = [
    aws_security_group.service_to_mq.id,
    aws_security_group.vpn_to_mq.id,
    aws_security_group.gocd_to_mq.id
  ]
  subnet_ids                 =  slice(module.vpc.private_subnets, 0, 2)

  logs {
    general = var.general_log
    audit   = var.audit_log
  }

  maintenance_window_start_time {
    day_of_week = var.maintenance_day_of_week
    time_of_day = var.maintenance_time_of_day
    time_zone   = var.maintenance_time_zone
  }

  user {
    username = data.aws_ssm_parameter.mq-admin-username.value
    password = data.aws_ssm_parameter.mq-admin-password.value
    console_access = var.grant_access_to_queues_through_vpn ? true : false
  }

  user {
    username = data.aws_ssm_parameter.mq-app-username.value
    password = data.aws_ssm_parameter.mq-app-password.value
    console_access = false
  }
  lifecycle {
    ignore_changes = [engine_version, host_instance_type]
  }

  tags = {
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}

data "aws_iam_policy_document" "mq-log-publishing-policy" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["arn:aws:logs:*:*:log-group:/aws/amazonmq/*"]

    principals {
      identifiers = ["mq.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_cloudwatch_log_resource_policy" "mq-log-publishing-policy" {
  policy_document = data.aws_iam_policy_document.mq-log-publishing-policy.json
  policy_name     = "${var.environment}-mq-log-publishing-policy"
}

resource "aws_ssm_parameter" "amqp-endpoint-0" {
  name        = "/repo/${var.environment}/output/${var.repo_name}/amqp-endpoint-0"
  description = "AMQP endpoint to MQ broker. Index: 0"
  type        = "String"
  value       = aws_mq_broker.deductor_mq_broker.instances.0.endpoints.1

  tags = {
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}

resource "aws_ssm_parameter" "amqp-endpoint-1" {
  name        = "/repo/${var.environment}/output/${var.repo_name}/amqp-endpoint-1"
  description = "AMQP endpoint to MQ broker. Index: 1"
  type        = "String"
  value       = aws_mq_broker.deductor_mq_broker.instances.1.endpoints.1

  tags = {
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}

resource "aws_ssm_parameter" "openwire-endpoint-0" {
  name        = "/repo/${var.environment}/output/${var.repo_name}/openwire-endpoint-0"
  description = "OpenWire endpoint to MQ broker. Index: 0"
  type        = "String"
  value       = aws_mq_broker.deductor_mq_broker.instances.0.endpoints.0

  tags = {
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}

resource "aws_ssm_parameter" "openwire-endpoint-1" {
  name        = "/repo/${var.environment}/output/${var.repo_name}/openwire-endpoint-1"
  description = "OpenWire endpoint to MQ broker. Index: 1"
  type        = "String"
  value       = aws_mq_broker.deductor_mq_broker.instances.1.endpoints.0

  tags = {
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}


resource "aws_security_group" "service_to_mq" {
  name        = "${var.environment}-service-to-mq"
  description = "controls access from repo services to AMQ"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Name = "${var.environment}-service-to-${var.component_name}-sg"
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}

resource "aws_ssm_parameter" "service_to_mq" {
  name = "/repo/${var.environment}/output/${var.repo_name}/service-to-mq-sg-id"
  type = "String"
  value = aws_security_group.service_to_mq.id
  tags = {
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}

resource "aws_security_group" "vpn_to_mq" {
  name        = "${var.environment}-vpn-to-mq"
  description = "controls access from VPN to AMQ"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Name = "${var.environment}-vpn-to-${var.component_name}-sg"
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}

resource "aws_security_group_rule" "vpn_to_mq_through_openwire" {
  count = var.grant_access_to_queues_through_vpn ? 1 : 0
  type = "ingress"
  protocol = "tcp"
  from_port = "61617"
  to_port = "61617"
  description = "Allow traffic from VPN to MQ through OpenWire"
  security_group_id = aws_security_group.vpn_to_mq.id
  source_security_group_id = aws_security_group.vpn.id
}

resource "aws_security_group_rule" "vpn_to_mq_through_amqp" {
  count = var.grant_access_to_queues_through_vpn ? 1 : 0
  type = "ingress"
  protocol = "tcp"
  from_port = "5671"
  to_port = "5671"
  description = "Allow traffic from VPN to MQ through AMQP"
  security_group_id = aws_security_group.vpn_to_mq.id
  source_security_group_id = aws_security_group.vpn.id
}

resource "aws_security_group_rule" "vpn_to_mq_web_console" {
  count = var.grant_access_to_queues_through_vpn ? 1 : 0
  type = "ingress"
  protocol = "tcp"
  from_port = "8162"
  to_port = "8162"
  description = "Allow traffic from VPN to MQ Web Console"
  security_group_id = aws_security_group.vpn_to_mq.id
  source_security_group_id = aws_security_group.vpn.id
}

resource "aws_security_group" "gocd_to_mq" {
  name        = "${var.environment}-gocd-to-mq"
  description = "controls access from gocd to AMQ"
  vpc_id      = module.vpc.vpc_id

  ingress {
    protocol = "tcp"
    from_port = "61617"
    to_port = "61617"
    description = "Allow traffic from gocd to MQ through OpenWire"
    security_groups = [data.aws_ssm_parameter.gocd_sg_id.value]
  }

  ingress {
    protocol        = "tcp"
    from_port       = "5671"
    to_port         = "5671"
    description = "Allow traffic from gocd to MQ through AMQP"
    security_groups = [data.aws_ssm_parameter.gocd_sg_id.value]
  }

  tags = {
    Name = "${var.environment}-gocd-to-${var.component_name}-sg"
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}

data "aws_ssm_parameter" "gocd_sg_id" {
  name = "/repo/${var.environment}/user-input/external/gocd-agent-sg-id"
}

resource "aws_ssm_parameter" "mq_broker_name" {
  name = "/repo/${var.environment}/output/${var.repo_name}/broker-name"
  type  = "String"
  value = aws_mq_broker.deductor_mq_broker.broker_name
}
