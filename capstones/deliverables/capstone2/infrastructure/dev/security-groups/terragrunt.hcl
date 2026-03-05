include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env      = local.env_vars.locals
}

terraform {
  source = "../../modules//security-groups"
}

dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = {
    vpc_id = "vpc-00000000000000000"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  vpc_id      = dependency.vpc.outputs.vpc_id
  environment = local.env.environment

  security_groups = {
    ec2 = {
      description = "EC2 instance traffic"
      ingress_rules = [
        { description = "SSH",  from_port = 22, to_port = 22, ip_protocol = "tcp", cidr_ipv4 = "10.0.0.0/8" },
        { description = "HTTP", from_port = 80, to_port = 80, ip_protocol = "tcp", cidr_ipv4 = "0.0.0.0/0" },
      ]
    }
  }
}
