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
    vpc_id = "vpc-000000000"
    igw_id = "igw-000000000"
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
    "public-subnet-a" = {
      name              = "prod-public-subnet-a"
      cidr_block        = "10.1.1.0/24"
      availability_zone = "us-east-1a"
      tier              = "public"
    }
    "public-subnet-b" = {
      name              = "prod-public-subnet-b"
      cidr_block        = "10.1.3.0/24"
      availability_zone = "us-east-1b"
      tier              = "public"
    }
    "private-subnet-a" = {
      name              = "prod-private-subnet-a"
      cidr_block        = "10.1.2.0/24"
      availability_zone = "us-east-1a"
      tier              = "private"
    }
    "private-subnet-b" = {
      name              = "prod-private-subnet-b"
      cidr_block        = "10.1.4.0/24"
      availability_zone = "us-east-1b"
      tier              = "private"
    }
  }
}
