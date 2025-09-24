environment = "pre-prod"

deductions_private_cidr = "10.22.0.0/16"
deductions_core_cidr    = "10.27.0.0/16"

deductions_private_public_subnets    = ["10.22.101.0/24", "10.22.102.0/24", "10.22.103.0/24"]
deductions_private_private_subnets   = ["10.22.1.0/24", "10.22.2.0/24", "10.22.3.0/24"]
deductions_private_database_subnets  = ["10.22.111.0/24", "10.22.112.0/24", "10.22.113.0/24"]
deductions_private_azs               = ["eu-west-2b", "eu-west-2a", "eu-west-2c"]
deductions_private_vpn_client_subnet = "10.233.200.0/22"

deductions_core_private_subnets  = ["10.27.1.0/24", "10.27.2.0/24", "10.27.3.0/24"]
deductions_core_database_subnets = ["10.27.111.0/24", "10.27.112.0/24", "10.27.113.0/24"]
deductions_core_azs              = ["eu-west-2b", "eu-west-2a", "eu-west-2c"]

mhs_cidr_newbits = 8

repo_mhs_cluster_domain_name = "mhs.patient-deductions.nhs.uk"

mhs_vpc_cidr_block               = "10.36.0.0/16"
mhs_repo_public_subnets_inbound  = ["10.36.112.0/22", "10.36.116.0/22", "10.36.120.0/22"]
mhs_repo_public_subnets_outbound = ["10.36.140.0/22", "10.36.144.0/22", "10.36.148.0/22"]
mhs_repo_private_subnets         = ["10.36.128.0/22", "10.36.132.0/22", "10.36.136.0/22"]

inbound_sig_ips = ["3.11.206.30/32", "3.8.223.81/32", "35.178.32.211/32", "3.11.177.31/32", "35.177.15.89/32", "3.11.199.83/32", "18.132.113.121/32", "18.132.31.159/32", "35.178.64.126/32"]

grant_access_to_queues_through_vpn = true
is_restricted_account              = true

s3_backup_enabled = true