include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env      = local.env_vars.locals
}

terraform {
  source = "../../../modules//vpc"
}

inputs = {
  vpc_cidr    = local.env.vpc_cidr
  environment = local.env.environment
  tags = {
    Environment = local.env.environment
    Project     = "capstone"
  }
}
