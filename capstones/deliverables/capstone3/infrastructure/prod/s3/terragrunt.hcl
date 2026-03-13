include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env      = local.env_vars.locals
}

terraform {
  source = "../../../modules//s3"
}

inputs = {
  environment = local.env.environment
  buckets = {
    "capstone-prod-justo-gqdw34" = {
      versioning_enabled     = true
      noncurrent_expiry_days = 30
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Principal = {
              AWS = "arn:aws:iam::127311923021:root"
            }
            Action   = "s3:PutObject"
            Resource = "arn:aws:s3:::capstone-prod-justo-gqdw34/alb-logs/AWSLogs/711784092484/*"
          }
        ]
      })
    }
  }
}
