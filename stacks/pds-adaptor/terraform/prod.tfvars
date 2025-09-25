environment = "prod"

task_cpu    = 256
task_memory = 512
port        = 8080

service_desired_count = "2"

alb_deregistration_delay = 15

log_level = "info"

grant_access_through_vpn = false