provider "aws" {
  region = var.region
}

provider "aws" {
  alias  = "ci"
  region = var.region
  assume_role {
    role_arn     = "arn:aws:iam::${var.common_account_id}:role/${var.common_account_role}"
    session_name = "common-${var.environment}-cross-account"
  }
}

terraform {
  backend "s3" {
    encrypt = true
  }
}

locals {
  first_half_mhs_cidr_block  = cidrsubnets(var.mhs_vpc_cidr_block, 1, 1)[0]
  second_half_mhs_cidr_block = cidrsubnets(var.mhs_vpc_cidr_block, 1, 1)[1]
  repo_cidr_block            = var.deploy_mhs_test_harness ? local.first_half_mhs_cidr_block : var.mhs_vpc_cidr_block
}

module "repo" {
  source = "./modules/mhs/"
  providers = {
    aws    = aws
    aws.ci = aws.ci
  }
  environment                      = var.environment
  mhs_vpc_cidr_block               = local.repo_cidr_block
  mhs_vpc_additional_cidr_block    = var.mhs_vpc_additional_cidr_block
  repo_name                        = var.repo_name
  cluster_name                     = "repo"
  deductions_private_cidr          = var.deductions_private_cidr
  region                           = var.region
  mhs_private_cidr_blocks          = var.mhs_repo_private_subnets
  mhs_public_subnets_inbound       = var.mhs_repo_public_subnets_inbound
  mhs_public_subnets_outbound      = var.mhs_repo_public_subnets_outbound
  deductions_private_vpc_id        = local.deductions_private_vpc_id
  mhs_cluster_domain_name          = var.repo_mhs_cluster_domain_name
  gocd_cidr                        = var.gocd_cidr
  deploy_cross_account_vpc_peering = var.deploy_cross_account_vpc_peering
  inbound_sig_ips                  = var.inbound_sig_ips
}

module "test-harness" {
  source = "./modules/mhs/"
  providers = {
    aws    = aws
    aws.ci = aws.ci
  }
  count                            = var.deploy_mhs_test_harness ? 1 : 0
  environment                      = var.environment
  mhs_vpc_cidr_block               = local.second_half_mhs_cidr_block
  mhs_vpc_additional_cidr_block    = var.mhs_vpc_additional_cidr_block
  repo_name                        = var.repo_name
  cluster_name                     = "test-harness"
  deductions_private_cidr          = var.deductions_private_cidr
  region                           = var.region
  mhs_private_cidr_blocks          = var.mhs_test_harness_private_subnets
  mhs_public_subnets_inbound       = var.mhs_test_harness_public_subnets_inbound
  mhs_public_subnets_outbound      = var.mhs_test_harness_public_subnets_outbound
  deductions_private_vpc_id        = local.deductions_private_vpc_id
  mhs_cluster_domain_name          = var.test_harness_mhs_cluster_domain_name
  gocd_cidr                        = var.gocd_cidr
  deploy_cross_account_vpc_peering = var.deploy_cross_account_vpc_peering
  inbound_sig_ips                  = var.inbound_sig_ips
}

module "deductions-private" {
  source = "./modules/deductions-private/"
  providers = {
    aws    = aws
    aws.ci = aws.ci
  }
  environment    = var.environment
  cidr           = var.deductions_private_cidr
  component_name = var.deductions_private_component_name

  public_subnets           = var.deductions_private_public_subnets
  private_subnets          = var.deductions_private_private_subnets
  database_subnets         = var.deductions_private_database_subnets
  azs                      = var.deductions_private_azs
  environment_private_zone = aws_route53_zone.environment_private
  environment_public_zone  = aws_route53_zone.environment_public

  gocd_cidr                       = var.gocd_cidr
  deductions_core_cidr            = var.deductions_core_cidr
  repo_mhs_vpc_cidr_block         = local.repo_cidr_block
  test_harness_mhs_vpc_cidr_block = var.deploy_mhs_test_harness ? local.second_half_mhs_cidr_block : ""
  deploy_mhs_test_harness         = var.deploy_mhs_test_harness

  broker_name                = "deductor-amq-broker-${var.environment}"
  deployment_mode            = var.deployment_mode
  mq_deployment_mode         = var.mq_deployment_mode
  engine_type                = var.engine_type
  engine_version             = var.engine_version
  host_instance_type         = var.host_instance_type
  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  apply_immediately          = var.apply_immediately
  general_log                = var.general_log
  audit_log                  = var.audit_log
  maintenance_day_of_week    = var.maintenance_day_of_week
  maintenance_time_of_day    = var.maintenance_time_of_day
  maintenance_time_zone      = var.maintenance_time_zone
  vpn_client_subnet          = var.deductions_private_vpn_client_subnet

  state_db_allocated_storage = var.state_db_allocated_storage
  state_db_engine_version    = var.state_db_engine_version
  state_db_instance_class    = var.state_db_instance_class

  core_private_vpc_peering_connection_id     = aws_vpc_peering_connection.core_private.id
  repo_mhs_vpc_peering_connection_id         = module.repo.private_mhs_vpc_peering_id
  test_harness_mhs_vpc_peering_connection_id = join(",", module.test-harness.*.private_mhs_vpc_peering_id)
  deploy_cross_account_vpc_peering           = var.deploy_cross_account_vpc_peering
  grant_access_to_queues_through_vpn         = var.grant_access_to_queues_through_vpn
}

module "deductions-core" {
  source = "./modules/deductions-core/"
  providers = {
    aws    = aws
    aws.ci = aws.ci
  }
  environment    = var.environment
  component_name = var.deductions_core_component_name

  cidr                                   = var.deductions_core_cidr
  deductions_private_cidr                = var.deductions_private_cidr
  gocd_cidr                              = var.gocd_cidr
  private_subnets                        = var.deductions_core_private_subnets
  database_subnets                       = var.deductions_core_database_subnets
  azs                                    = var.deductions_core_azs
  core_private_vpc_peering_connection_id = aws_vpc_peering_connection.core_private.id
  gocd_environment                       = "prod"
  deploy_cross_account_vpc_peering       = var.deploy_cross_account_vpc_peering
}

module "utils" {
  source      = "./modules/utils"
  region      = var.region
  environment = var.environment
}

locals {
  deductions_core_vpc_id    = module.deductions-core.vpc_id
  deductions_private_vpc_id = module.deductions-private.vpc_id
  repo_mhs_vpc_id           = module.repo.vpc_id
  test_harness_mhs_vpc_id   = join(",", module.test-harness.*.vpc_id)

  deductions_core_private_subnets_route_table_id    = module.deductions-core.private_subnets_route_table_id
  deductions_private_private_subnets_route_table_id = module.deductions-private.private_subnets_route_table_id
  deductions_private_public_subnets_route_table_id  = module.deductions-private.public_subnets_route_table_id
}
