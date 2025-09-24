environment = "dev"

mhs_cidr_newbits = 8

deductions_private_cidr              = "10.20.0.0/16"
deductions_private_public_subnets    = ["10.20.101.0/24", "10.20.102.0/24"]
deductions_private_private_subnets   = ["10.20.1.0/24", "10.20.2.0/24"]
deductions_private_database_subnets  = ["10.20.111.0/24", "10.20.112.0/24"]
deductions_private_azs               = ["eu-west-2a", "eu-west-2b"]
deductions_private_vpn_client_subnet = "10.233.232.0/22"

deductions_core_cidr             = "10.25.0.0/16"
deductions_core_private_subnets  = ["10.25.1.0/24", "10.25.2.0/24"]
deductions_core_database_subnets = ["10.25.111.0/24", "10.25.112.0/24"]
deductions_core_azs              = ["eu-west-2a", "eu-west-2b"]

mhs_repo_private_subnets                 = ["10.34.0.0/22", "10.34.4.0/22", "10.34.8.0/22"]
mhs_repo_public_subnets_inbound          = ["10.34.12.0/22", "10.34.16.0/22", "10.34.20.0/22"]
mhs_repo_public_subnets_outbound         = ["10.34.24.0/22", "10.34.28.0/22", "10.34.32.0/22"]
mhs_test_harness_private_subnets         = ["10.34.128.0/22", "10.34.132.0/22", "10.34.136.0/22"]
mhs_test_harness_public_subnets_inbound  = ["10.34.140.0/22", "10.34.144.0/22", "10.34.148.0/22"]
mhs_test_harness_public_subnets_outbound = ["10.34.152.0/22", "10.34.156.0/22", "10.34.160.0/22"]


repo_mhs_cluster_domain_name         = "mhs.patient-deductions.nhs.uk"
test_harness_mhs_cluster_domain_name = "test-harness-mhs.patient-deductions.nhs.uk"
mhs_vpc_cidr_block                   = "10.34.0.0/16"


deploy_mhs_test_harness          = true
deploy_cross_account_vpc_peering = true

inbound_sig_ips = ["3.11.206.30/32", "3.8.223.81/32", "35.178.32.211/32", "3.11.177.31/32", "35.177.15.89/32", "3.11.199.83/32", "18.132.113.121/32", "18.132.31.159/32", "35.178.64.126/32"]

grant_access_to_queues_through_vpn = true
