environment    = "test"
component_name = "pds-adaptor"
dns_name       = "pds-adaptor"
repo_name      = "prm-deductions-pds-adaptor"

task_cpu    = 256
task_memory = 512
port        = 8080

service_desired_count = "2"

alb_deregistration_delay = 15

grant_access_through_vpn = true