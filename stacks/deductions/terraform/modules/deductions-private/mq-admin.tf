module "mq-admin" {
  count = var.grant_access_to_queues_through_vpn ? 1 : 0
  source    = "./mq-admin"
  environment    = var.environment
  repo_name = var.repo_name
  region = var.region
  component_name = var.component_name
  vpn_sg_id = aws_security_group.vpn.id
  mq_broker_instances = aws_mq_broker.deductor_mq_broker.instances
  deductions_private_vpc_private_subnets = module.vpc.private_subnets
  deductions_private_vpc_id = module.vpc.vpc_id
  environment_public_zone = var.environment_public_zone
  environment_private_zone = var.environment_private_zone
  service_to_mq_admin_sg_id = aws_security_group.service_to_mq.id
  vpc_id = module.vpc.vpc_id
}