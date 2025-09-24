environment          = "dev"

synthetic_patient_prefix = "96937"
process_only_synthetic_patients = false

scale_up_expression = "( (MINUTE(m1)>=0 )),10, 0"
enable_scale_action = false

ecs_desired_count = 0
repo_process_only_safe_listed_ods_codes = true