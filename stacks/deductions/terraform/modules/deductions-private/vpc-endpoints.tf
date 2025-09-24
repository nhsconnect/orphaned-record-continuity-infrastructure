resource "aws_vpc_endpoint" "ecr-dkr" {

    vpc_id       = module.vpc.vpc_id
    service_name = "com.amazonaws.${var.region}.ecr.dkr"

    subnet_ids = module.vpc.private_subnets
    vpc_endpoint_type = "Interface"

    security_group_ids = [aws_security_group.ecr-endpoint-sg.id]

    private_dns_enabled = true

    tags = {
        Name            = "${var.environment}-${var.component_name}-ecr-dkr-endpoint"
        CreatedBy   = var.repo_name
        Environment = var.environment
    }
}

resource "aws_vpc_endpoint" "ecr-api" {
    vpc_id = module.vpc.vpc_id
    service_name = "com.amazonaws.${var.region}.ecr.api"

    subnet_ids = module.vpc.private_subnets
    vpc_endpoint_type = "Interface"

    security_group_ids = [aws_security_group.ecr-endpoint-sg.id]

    private_dns_enabled = true

    tags = {
        Name = "${var.environment}-${var.component_name}-ecr-api-endpoint"
        CreatedBy = var.repo_name
        Environment = var.environment
    }
}

resource "aws_security_group" "ecr-endpoint-sg" {
    name        = "${var.environment}-${var.component_name}-ecr-endpoint-sg"
    description = "Taffic for the ECR VPC endpoint."
    vpc_id      = module.vpc.vpc_id

    ingress {
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"

        # Allow to pull images from the local network
        cidr_blocks = [var.cidr]
    }

    tags = {
        Name            = "${var.environment}-${var.component_name}-ecr-endpoint-sg"
        CreatedBy   = var.repo_name
        Environment = var.environment
    }
}

resource "aws_vpc_endpoint" "cloudwatch-logs" {
    vpc_id       = module.vpc.vpc_id
    service_name = "com.amazonaws.${var.region}.logs"

    subnet_ids = module.vpc.private_subnets
    vpc_endpoint_type = "Interface"

    security_group_ids = [aws_security_group.logs-endpoint-sg.id]

    private_dns_enabled = true

    tags = {
        Name            = "${var.environment}-${var.component_name}-logs-endpoint"
        CreatedBy   = var.repo_name
        Environment = var.environment
    }
}

resource "aws_security_group" "logs-endpoint-sg" {
    name        = "${var.environment}-${var.component_name}-logs-endpoint-sg"
    description = "Traffic for the CloudWatch Logs VPC endpoint."
    vpc_id      = module.vpc.vpc_id

    ingress {
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"

        # Allow to log from the local network
        cidr_blocks = [var.cidr]
    }

    tags = {
        Name            = "${var.environment}-${var.component_name}-logs-endpoint-sg"
        CreatedBy   = var.repo_name
        Environment = var.environment
    }
}

resource "aws_vpc_endpoint" "ssm" {
    vpc_id = module.vpc.vpc_id
    service_name = "com.amazonaws.${var.region}.ssm"

    subnet_ids = module.vpc.private_subnets
    vpc_endpoint_type = "Interface"

    security_group_ids = [aws_security_group.ssm-endpoint-sg.id]

    private_dns_enabled = true

    tags = {
        Name = "${var.environment}-${var.component_name}-ssm-endpoint"
        CreatedBy = var.repo_name
        Environment = var.environment
    }
}

resource "aws_security_group" "ssm-endpoint-sg" {
    name = "${var.environment}-${var.component_name}-ssm-endpoint-sg"
    description = "Traffic for the SSM VPC endpoint."
    vpc_id = module.vpc.vpc_id

    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"

        # Allow to log from the local network
        cidr_blocks = [var.cidr]
    }

    tags = {
        Name = "${var.environment}-${var.component_name}-ssm-endpoint-sg"
        CreatedBy = var.repo_name
        Environment = var.environment
    }
}

resource "aws_vpc_endpoint" "s3" {
    vpc_id = module.vpc.vpc_id
    service_name = "com.amazonaws.${var.region}.s3"
    vpc_endpoint_type = "Gateway"
    route_table_ids = module.vpc.private_route_table_ids

    tags = {
        Name = "${var.environment}-${var.component_name}-s3-endpoint"
        CreatedBy = var.repo_name
        Environment = var.environment
    }
}

resource "aws_vpc_endpoint" "sqs" {
    vpc_id = module.vpc.vpc_id
    service_name = "com.amazonaws.${var.region}.sqs"

    subnet_ids = module.vpc.private_subnets
    vpc_endpoint_type = "Interface"

    security_group_ids = [aws_security_group.sqs-sg.id]

    private_dns_enabled = true

    tags = {
        Name = "${var.environment}-${var.component_name}-sqs-endpoint"
        CreatedBy = var.repo_name
        Environment = var.environment
    }
}

resource "aws_vpc_endpoint" "sns" {
    vpc_id = module.vpc.vpc_id
    service_name = "com.amazonaws.${var.region}.sns"

    subnet_ids = module.vpc.private_subnets
    vpc_endpoint_type = "Interface"

    security_group_ids = [aws_security_group.sns-sg.id]

    private_dns_enabled = true

    tags = {
        Name = "${var.environment}-${var.component_name}-sns-endpoint"
        CreatedBy = var.repo_name
        Environment = var.environment
    }
}

resource "aws_vpc_endpoint" "monitoring" {
    vpc_id = module.vpc.vpc_id
    service_name = "com.amazonaws.${var.region}.monitoring"

    subnet_ids = module.vpc.private_subnets
    vpc_endpoint_type = "Interface"

    security_group_ids = [aws_security_group.monitoring-sg.id]

    private_dns_enabled = true

    tags = {
        Name = "${var.environment}-${var.component_name}-monitoring-endpoint"
        CreatedBy = var.repo_name
        Environment = var.environment
    }
}

resource "aws_security_group" "sqs-sg" {
    name = "${var.environment}-${var.component_name}-sqs-endpoint-sg"
    description = "Traffic for the sqs queues VPC endpoint."
    vpc_id = module.vpc.vpc_id

    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"

        # Allow to log from the local network
        cidr_blocks = [var.cidr]
    }

    tags = {
        Name = "${var.environment}-${var.component_name}-sqs-sg"
        CreatedBy = var.repo_name
        Environment = var.environment
    }
}

resource "aws_security_group" "sns-sg" {
    name = "${var.environment}-${var.component_name}-sns-endpoint-sg"
    description = "Traffic for the sns VPC endpoint."
    vpc_id = module.vpc.vpc_id

    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"

        # Allow to log from the local network
        cidr_blocks = [var.cidr]
    }

    tags = {
        Name = "${var.environment}-${var.component_name}-sns-endpoint-sg"
        CreatedBy = var.repo_name
        Environment = var.environment
    }
}

resource "aws_security_group" "monitoring-sg" {
    name = "${var.environment}-${var.component_name}-monitoring-endpoint-sg"
    description = "Traffic for the monitoring VPC endpoint."
    vpc_id = module.vpc.vpc_id

    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"

        # Allow to log from the local network
        cidr_blocks = [var.cidr]
    }

    tags = {
        Name = "${var.environment}-${var.component_name}-monitoring-endpoint-sg"
        CreatedBy = var.repo_name
        Environment = var.environment
    }
}

resource "aws_vpc_endpoint" "dynamodb_gateway_endpoint" {
    vpc_id = module.vpc.vpc_id
    service_name = "com.amazonaws.${var.region}.dynamodb"
    vpc_endpoint_type = "Gateway"
    route_table_ids = module.vpc.private_route_table_ids

    tags = {
        Name = "${var.environment}-${var.component_name}-dynamo-endpoint"
        CreatedBy = var.repo_name
        Environment = var.environment
    }
}

data "aws_prefix_list" "private_dynamodb" {
    prefix_list_id = aws_vpc_endpoint.dynamodb_gateway_endpoint.prefix_list_id
}

data "aws_prefix_list" "s3" {
    prefix_list_id = aws_vpc_endpoint.s3.prefix_list_id
}

resource "aws_ssm_parameter" "dynamodb_prefix_list_id" {
    name = "/repo/${var.environment}/output/${var.repo_name}/dynamodb_prefix_list_id"
    type = "String"
    value = data.aws_prefix_list.private_dynamodb.id
}

resource "aws_ssm_parameter" "s3_prefix_list_id" {
    name = "/repo/${var.environment}/output/${var.repo_name}/s3_prefix_list_id"
    type = "String"
    value = data.aws_prefix_list.s3.id
}