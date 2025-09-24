environment = "test"

deductions_private_cidr = "10.21.0.0/16"
deductions_core_cidr    = "10.26.0.0/16"

deductions_private_public_subnets    = ["10.21.101.0/24", "10.21.102.0/24"]
deductions_private_private_subnets   = ["10.21.1.0/24", "10.21.2.0/24"]
deductions_private_database_subnets  = ["10.21.111.0/24", "10.21.112.0/24"]
deductions_private_azs               = ["eu-west-2b", "eu-west-2a"]
deductions_private_vpn_client_subnet = "10.233.200.0/22"

deductions_core_private_subnets  = ["10.26.1.0/24", "10.26.2.0/24"]
deductions_core_database_subnets = ["10.26.111.0/24", "10.26.112.0/24"]
deductions_core_azs              = ["eu-west-2b", "eu-west-2a"]

mhs_cidr_newbits = 2

mhs_repo_public_subnets_inbound  = ["10.239.69.0/27", "10.239.69.32/27", "10.239.69.64/27"]
mhs_repo_public_subnets_outbound = ["10.239.69.96/27", "10.239.69.128/27", "10.239.69.160/27"]
mhs_repo_private_subnets         = ["10.239.68.128/27", "10.239.68.160/27", "10.239.68.192/27"]

mhs_vpc_cidr_block            = "10.239.68.128/25" # This is pre-allocated by NHSD
mhs_vpc_additional_cidr_block = "10.239.69.0/24"

deploy_mhs_test_harness = false

repo_mhs_cluster_domain_name = "mhs.patient-deductions.nhs.uk"
inbound_sig_ips              = ["3.11.206.30/32", "3.8.223.81/32", "35.178.32.211/32", "3.11.177.31/32", "35.177.15.89/32", "3.11.199.83/32", "18.132.113.121/32", "18.132.31.159/32", "35.178.64.126/32"]

grant_access_to_queues_through_vpn = true

