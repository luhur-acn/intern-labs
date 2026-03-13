include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env      = local.env_vars.locals
}

terraform {
  source = "../../../modules//ec2"
}

dependency "subnets" {
  config_path = "../subnets"
  mock_outputs = {
    subnet_ids = { 
      "public-subnet-a"  = "subnet-0b97151b8f1f45bf4"
      "private-subnet-a" = "subnet-08c3d7f438768df76"
    }
  }
}

dependency "security_groups" {
  config_path = "../security-groups"
  mock_outputs = {
    security_group_ids = { "ec2" = "sg-065265d8b0ddd554f" }
  }
}

inputs = {
  environment = local.env.environment
  tags = {
    Name        = "web-dev"
    Environment = local.env.environment
    Project     = "capstone"
  }
  
  instances = {
    "web" = {
      ami_id             = local.env.ami_id
      instance_type      = "t3.micro"
      subnet_id          = dependency.subnets.outputs.subnet_ids["private-subnet-a"]
      security_group_ids = [dependency.security_groups.outputs.security_group_ids["ec2"]]
      name               = "web-dev"
      user_data          = "#!/bin/bash\nyum update -y; yum install -y httpd\necho '<h1>Capstone DEV Server</h1>' > /var/www/html/index.html\nsystemctl start httpd; systemctl enable httpd"
    }
  }
}
