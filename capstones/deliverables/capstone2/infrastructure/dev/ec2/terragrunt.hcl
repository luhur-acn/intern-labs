include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env      = local.env_vars.locals
}

terraform {
  source = "../../modules//ec2"
}

dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = {
    private_subnet_ids = ["subnet-000000000", "subnet-111111111"]
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "security_groups" {
  config_path = "../security-groups"
  mock_outputs = {
    security_group_ids = { ec2 = "sg-000000000" }
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  environment = local.env.environment

  instances = {
    web = {
      ami_id             = local.env.ami_id
      instance_type      = "t3.micro"
      subnet_id          = dependency.vpc.outputs.private_subnet_ids[0]
      security_group_ids = [dependency.security_groups.outputs.security_group_ids["ec2"]]
      user_data          = <<-EOF
        #!/bin/bash
        yum update -y
        yum install -y httpd
        echo "<h1>IaC Capstone - ${local.env.environment} - web</h1>" > /var/www/html/index.html
        systemctl start httpd && systemctl enable httpd
      EOF
    }
  }
}
