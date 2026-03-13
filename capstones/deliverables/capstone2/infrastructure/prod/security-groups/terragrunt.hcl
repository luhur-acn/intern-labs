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
    vpc_id = "vpc-111111111"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init", "plan-all", "validate-all"]
}

inputs = {
  vpc_id      = dependency.vpc.outputs.vpc_id

  security_groups = {
    nlb = {
      description = "NLB security group"
      ingress_rules = [
        { description = "HTTP from internet", from_port = 80, to_port = 80, ip_protocol = "tcp", cidr_ipv4 = "0.0.0.0/0" }
      ]
      egress_rules = [
        { description = "Allow all outbound", from_port = 0, to_port = 0, ip_protocol = "-1", cidr_ipv4 = "0.0.0.0/0" }
      ]
    }
    alb = {
      description = "ALB security group"
      ingress_rules = [
        { description = "HTTP from NLB", from_port = 80, to_port = 80, ip_protocol = "tcp", referenced_sg_key = "nlb" },
        { description = "HTTPS from internet", from_port = 443, to_port = 443, ip_protocol = "tcp", cidr_ipv4 = "0.0.0.0/0" }
      ]
      egress_rules = [
        { description = "HTTP to EC2", from_port = 80, to_port = 80, ip_protocol = "tcp", referenced_sg_key = "ec2" }
      ]
    }
    ec2 = {
      description = "EC2 instances security group"
      ingress_rules = [
        { description = "HTTP from ALB", from_port = 80, to_port = 80, ip_protocol = "tcp", referenced_sg_key = "alb" },
        { description = "SSH from internal", from_port = 22, to_port = 22, ip_protocol = "tcp", cidr_ipv4 = "10.0.0.0/8" }
      ]
      egress_rules = [
        { description = "Allow all outbound", from_port = 0, to_port = 0, ip_protocol = "-1", cidr_ipv4 = "0.0.0.0/0" }
      ]
    }
  }
}
