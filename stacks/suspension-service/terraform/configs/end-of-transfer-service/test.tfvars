environment          = "test"

synthetic_patient_prefix = "96941"
process_only_synthetic_patients = true

scale_up_expression = "( (MINUTE(m1)==0 || MINUTE(m1)==15 || MINUTE(m1)==30 || MINUTE(m1)==45 )),10, 0"

ecs_desired_count = 0