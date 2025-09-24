environment = "prod"

deductions_private_cidr = "10.23.0.0/16"
deductions_core_cidr    = "10.28.0.0/16"

deductions_private_public_subnets    = ["10.23.101.0/24", "10.23.102.0/24", "10.23.103.0/24"]
deductions_private_private_subnets   = ["10.23.1.0/24", "10.23.2.0/24", "10.23.3.0/24"]
deductions_private_database_subnets  = ["10.23.111.0/24", "10.23.112.0/24", "10.23.113.0/24"]
deductions_private_azs               = ["eu-west-2b", "eu-west-2a", "eu-west-2c"]
deductions_private_vpn_client_subnet = "10.233.200.0/22"

deductions_core_private_subnets  = ["10.28.1.0/24", "10.28.2.0/24", "10.28.3.0/24"]
deductions_core_database_subnets = ["10.28.111.0/24", "10.28.112.0/24", "10.28.113.0/24"]
deductions_core_azs              = ["eu-west-2b", "eu-west-2a", "eu-west-2c"]

mhs_cidr_newbits = 8

repo_mhs_cluster_domain_name = "mhs.patient-deductions.nhs.uk"

mhs_vpc_cidr_block               = "10.37.0.0/16"
mhs_repo_public_subnets_inbound  = ["10.37.112.0/22", "10.37.116.0/22", "10.37.120.0/22"]
mhs_repo_public_subnets_outbound = ["10.37.140.0/22", "10.37.144.0/22", "10.37.148.0/22"]
mhs_repo_private_subnets         = ["10.37.128.0/22", "10.37.132.0/22", "10.37.136.0/22"]

inbound_sig_ips = ["18.132.56.40/32", "3.11.193.200/32", "35.176.248.137/32", "3.10.194.216/32", "35.176.231.190/32", "35.179.50.16/32", "18.132.85.195/32", "3.9.216.176/32", "35.179.32.68/32"]

deploy_prod_route53_zone = true
is_restricted_account    = true

s3_backup_enabled = true