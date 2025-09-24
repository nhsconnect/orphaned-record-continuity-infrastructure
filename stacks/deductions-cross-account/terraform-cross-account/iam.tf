module "ci_roles" {
  source = "./iam-ci"
  count = var.provision_ci_account ? 1 : 0
}

module "environment_roles" {
  source = "./iam-environment"
  // TODO: Use condition with provision_strict_iam_roles
  count = var.provision_ci_account ? 0 : 1
  provision_strict_iam_roles = var.provision_strict_iam_roles
}

module "environment_strict_roles" {
  source = "./iam-strict-environment"
  count = var.provision_strict_iam_roles ? 1 : 0
  state_bucket_infix = var.state_bucket_infix
  environment = var.environment
}

