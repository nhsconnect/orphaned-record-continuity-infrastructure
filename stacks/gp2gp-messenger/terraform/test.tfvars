environment    = "test"
component_name = "gp2gp-messenger"
dns_name       = "gp2gp-messenger"
repo_name      = "prm-deductions-gp2gp-messenger"

task_cpu    = 256
task_memory = 512
port        = 3000

service_desired_count = "2"

alb_deregistration_delay = 15

grant_access_through_vpn = true
spine_org_code           = "YES"