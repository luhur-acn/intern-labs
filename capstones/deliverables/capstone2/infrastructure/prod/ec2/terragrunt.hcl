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
    private_subnet_ids = ["subnet-222222222", "subnet-333333333", "subnet-444444444"]
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "security_groups" {
  config_path = "../security-groups"
  mock_outputs = {
    security_group_ids = { ec2 = "sg-111111111" }
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  instances = merge(
    # Dynamic web servers across all AZs
    {
      for idx, subnet_id in dependency.vpc.outputs.private_subnet_ids : "web-${idx + 1}" => {
        ami_id             = local.env.ami_id
        instance_type      = "t3.small"
        subnet_id          = subnet_id
        security_group_ids = [dependency.security_groups.outputs.security_group_ids["ec2"]]
        user_data          = <<-EOF
          #!/bin/bash
          yum update -y && yum install -y httpd
          echo "<h1>IaC Capstone - prod - web</h1>" > /var/www/html/index.html
          systemctl start httpd && systemctl enable httpd
        EOF
      }
    },
    # Example of a unique instance with different config
    {
      "app-special" = {
        ami_id             = local.env.ami_id
        instance_type      = "t3.medium" # Different type
        subnet_id          = dependency.vpc.outputs.private_subnet_ids[0]
        security_group_ids = [dependency.security_groups.outputs.security_group_ids["ec2"]]
        user_data          = "# Special config"
      }
    }
  )
}
