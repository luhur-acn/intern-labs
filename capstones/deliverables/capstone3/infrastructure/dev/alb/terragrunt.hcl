include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env      = local.env_vars.locals
}

terraform {
  source = "../../../modules//alb"
}

dependency "subnets" {
  config_path = "../subnets"
  mock_outputs = {
    public_subnet_ids = ["subnet-031554c80d082ad50", "subnet-09774a5e6cd4fc675"]
  }
}

dependency "security_groups" {
  config_path = "../security-groups"
  mock_outputs = {
    security_group_ids = { "alb" = "sg-017d13c99a80bd702" }
  }
}

dependency "ec2" {
  config_path = "../ec2"
  mock_outputs = {
    instance_ids = { "web" = "i-0fb7d369ebf2ab629" }
  }
}

dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = {
    vpc_id = "vpc-0ddbf980fe31ea317"
  }
}

inputs = {
  environment        = local.env.environment
  name               = "capstone-dev-alb"
  vpc_id             = dependency.vpc.outputs.vpc_id
  subnet_ids         = dependency.subnets.outputs.public_subnet_ids
  security_group_ids = [dependency.security_groups.outputs.security_group_ids["alb"]]

  target_groups = {
    "capstone-dev-ec2-tg" = {
      port                               = 80
      protocol                           = "HTTP"
      target_type                        = "instance"
      deregistration_delay               = 300
      load_balancing_algorithm_type      = "round_robin"
      load_balancing_anomaly_mitigation  = "off"
      load_balancing_cross_zone_enabled  = "use_load_balancer_configuration"
      protocol_version                   = "HTTP1"
      lambda_multi_value_headers_enabled = false
      proxy_protocol_v2                  = false
      health_check_path                  = "/"
      healthy_threshold                  = 5
      unhealthy_threshold                = 2
      interval                           = 30
      timeout                            = 5
      matcher                            = "200"
    }
  }

  target_group_attachments = {
    web = {
      target_group_key = "capstone-dev-ec2-tg"
      target_id        = dependency.ec2.outputs.instance_ids["web"]
    }
  }

  listeners = {
    http = {
      port             = 80
      protocol         = "HTTP"
      target_group_key = "capstone-dev-ec2-tg"
    }
  }
}
