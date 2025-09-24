environment = "perf"

deductions_private_cidr = "10.24.0.0/16"
deductions_core_cidr    = "10.29.0.0/16"

deductions_private_public_subnets    = ["10.24.101.0/24", "10.24.102.0/24"]
deductions_private_private_subnets   = ["10.24.1.0/24", "10.24.2.0/24"]
deductions_private_database_subnets  = ["10.24.111.0/24", "10.24.112.0/24"]
deductions_private_azs               = ["eu-west-2b", "eu-west-2a"]
deductions_private_vpn_client_subnet = "10.233.200.0/22"

deductions_core_private_subnets  = ["10.29.1.0/24", "10.29.2.0/24"]
deductions_core_database_subnets = ["10.29.111.0/24", "10.29.112.0/24"]
deductions_core_azs              = ["eu-west-2b", "eu-west-2a"]

mhs_cidr_newbits = 2

repo_mhs_cluster_domain_name = "mhs.patient-deductions.nhs.uk"

mhs_vpc_cidr_block               = "10.35.0.0/16"
mhs_repo_public_subnets_inbound  = ["10.35.112.0/22", "10.35.116.0/22", "10.35.120.0/22"]
mhs_repo_public_subnets_outbound = ["10.35.140.0/22", "10.35.144.0/22", "10.35.148.0/22"]
mhs_repo_private_subnets         = ["10.35.128.0/22", "10.35.132.0/22", "10.35.136.0/22"]

inbound_sig_ips = ["3.11.206.30/32", "3.8.223.81/32", "35.178.32.211/32", "3.11.177.31/32", "35.177.15.89/32", "3.11.199.83/32", "18.132.113.121/32", "18.132.31.159/32", "35.178.64.126/32"]

grant_access_to_queues_through_vpn = true

