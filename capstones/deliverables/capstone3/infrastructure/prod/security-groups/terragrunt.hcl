include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env      = local.env_vars.locals
}

terraform {
  source = "../../../modules//security-groups"
}

dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = {
    vpc_id = "vpc-000000000"
  }
}

inputs = {
  vpc_id      = dependency.vpc.outputs.vpc_id
  environment = local.env.environment
  project     = "capstone"
  tags = {
    Environment = local.env.environment
    Project     = "capstone"
  }

  security_groups = {
    alb = {
      description = "ALB SG for prod"
      ingress_rules = [
        {
          from_port   = 80
          to_port     = 80
          ip_protocol = "tcp"
          cidr_ipv4   = "0.0.0.0/0"
        }
      ]
    }
    ec2 = {
      description = "EC2 SG for prod"
      ingress_rules = [
        {
          description               = "HTTP from ALB"
          from_port                 = 80
          to_port                   = 80
          ip_protocol               = "tcp"
          source_security_group_key = "alb"
        },
        {
          description = "SSH from my IP"
          from_port   = 22
          to_port     = 22
          ip_protocol = "tcp"
          cidr_ipv4   = "158.140.170.73/32"
        }
      ]
    }
  }
}
