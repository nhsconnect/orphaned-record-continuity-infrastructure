region    = "eu-west-2"
repo_name = "prm-deductions-infra"

deductions_private_component_name = "deductions-private"
deductions_core_component_name    = "deductions-core"

gocd_cidr = "10.1.0.0/16"

deployment_mode            = "ACTIVE_STANDBY_MULTI_AZ"
mq_deployment_mode         = "SINGLE_INSTANCE"
engine_type                = "ActiveMQ"
engine_version             = "5.18.4"
host_instance_type         = "mq.t3.micro"
auto_minor_version_upgrade = "true"
apply_immediately          = "false"
general_log                = "true"
audit_log                  = "true"
maintenance_day_of_week    = "SUNDAY"
maintenance_time_of_day    = "03:00"
maintenance_time_zone      = "GMT"
state_db_allocated_storage = "20"
state_db_engine_version    = "11.5"
state_db_instance_class    = "db.t2.small"

mhs_test_harness_public_subnets_inbound  = []
mhs_test_harness_public_subnets_outbound = []
mhs_test_harness_private_subnets         = []

deploy_mhs_test_harness            = false
deploy_cross_account_vpc_peering   = true
grant_access_to_queues_through_vpn = false