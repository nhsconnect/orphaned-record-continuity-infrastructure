locals {
    vpc_id                  = data.terraform_remote_state.network.outputs.vpc_id
    private_subnets         = data.terraform_remote_state.network.outputs.private_subnets
    private_route_table_ids = data.terraform_remote_state.network.outputs.private_route_table_ids
    private_subnet_cidrs    = data.terraform_remote_state.network.outputs.private_subnets_cidr_blocks
}

data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket         = "prm-deductions-${var.state_bucket_infix}terraform-state"
    key            = "deductions-infra-cross-account-${var.environment}/terraform.tfstate"
    region         = vars.region
    dynamodb_table = "prm-deductions-${var.environment}-terraform-table"
    encrypt = true
  }
}