include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env      = local.env_vars.locals
}

terraform {
  source = "../../modules//s3"
}

inputs = {
  buckets = {
    app-artifacts = {
      versioning_enabled     = true
      noncurrent_expiry_days = 90
    }
    app-logs = {
      versioning_enabled     = false
      noncurrent_expiry_days = 14
    }
  }
}
