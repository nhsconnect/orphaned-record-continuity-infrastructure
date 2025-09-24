# Deductions Private Outputs
output "deductions_private_private_subnets" {
  value = module.deductions-private.deductions_private_private_subnets
}

output "dns_server_1" {
  value = module.deductions-private.dns_server_1
}

output "deductions_core_private_subnets" {
  value = module.deductions-core.deductions_core_private_subnets
}
