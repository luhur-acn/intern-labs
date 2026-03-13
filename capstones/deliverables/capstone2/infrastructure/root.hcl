locals {
  env_vars    = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  environment = local.env_vars.locals.environment
  project     = "iac-capstone"
  region      = "us-east-1"
}

remote_state {
  backend = "s3"
  generate = {  
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket         = "iac-capstone-tfstate-justo1"
    key            = "${local.project}/${local.environment}/${path_relative_to_include()}/terraform.tfstate"
    region         = local.region
    encrypt        = true
    use_lockfile   = true
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "${local.region}"
  default_tags {
    tags = {
      Project     = "${local.project}"
      Environment = "${local.environment}"
      ManagedBy   = "Terragrunt"
    }
  }
}

provider "random" {}
EOF
}

inputs = {
  region      = local.region
  environment = local.environment
  tags = {
    Project     = local.project
    Environment = local.environment
    ManagedBy   = "Terragrunt"
  }
}
