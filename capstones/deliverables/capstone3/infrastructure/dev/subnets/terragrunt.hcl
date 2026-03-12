include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env      = local.env_vars.locals
}

terraform {
  source = "../../../modules//subnets"
}

dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = {
    vpc_id = "vpc-0ddbf980fe31ea317"
    igw_id = "igw-0aa4301115a79aa33"
  }
}

inputs = {
  vpc_id      = dependency.vpc.outputs.vpc_id
  igw_id      = dependency.vpc.outputs.igw_id
  environment = local.env.environment
  tags = {
    Environment = local.env.environment
    Project     = "capstone"
  }
  
  subnets = {
    "public-subnet-a"  = { name = "dev-public-subnet-a", cidr_block = "10.0.1.0/24", availability_zone = "us-east-1a", tier = "public" }
    "public-subnet-b"  = { name = "dev-public-subnet-b", cidr_block = "10.0.3.0/24", availability_zone = "us-east-1b", tier = "public" }
    "private-subnet-a" = { name = "dev-private-subnet-a", cidr_block = "10.0.2.0/24", availability_zone = "us-east-1a", tier = "private" }
    "private-subnet-b" = { name = "dev-private-subnet-b", cidr_block = "10.0.4.0/24", availability_zone = "us-east-1b", tier = "private" }
  }
}
