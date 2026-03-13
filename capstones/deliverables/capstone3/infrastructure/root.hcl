# infrastructure/root.hcl
# Shared configuration for all environments (Dev & Prod)

locals {
  # Load environment-specific variables
  env_hcl = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env     = local.env_hcl.locals.environment
  region  = "us-east-1"
  project = "capstone"
}

# Generate AWS provider block
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "${local.region}"
  default_tags {
    tags = {
      Project       = "${local.project}"
      Environment   = "${local.env}"
      MigrationDate = "${formatdate("YYYY-MM-DD", timestamp())}"
      Owner         = "Justo"
    }
  }
}
EOF
}

  # default_tags {
  #   tags = {
  #     Project     = "${local.project}"
  #     Environment = "${local.env}"
  #     # ManagedBy   = "Terragrunt"
  #   }
  # }
# Remote state management (S3 with Native Locking)
remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket       = "capstone-tfstate-justo-tv70lu"
    key          = "${local.project}/${local.env}/${path_relative_to_include()}/terraform.tfstate"
    region       = local.region
    encrypt      = true
    use_lockfile = true
  }
}
