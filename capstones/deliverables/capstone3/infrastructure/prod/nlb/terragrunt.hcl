include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env      = local.env_vars.locals
}

terraform {
  source = "../../../modules//nlb"
}

dependency "subnets" {
  config_path = "../subnets"
  mock_outputs = {
    subnet_ids = { "public-subnet-a" = "subnet-0a6728f0e798cd872" }
  }
}

dependency "alb" {
  config_path = "../alb"
  mock_outputs = {
    alb_arn = "arn:aws:elasticloadbalancing:us-east-1:281762848670:loadbalancer/app/capstone-prod-alb/1343b3bc4d311ba4"
  }
}

dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = {
    vpc_id = "vpc-0db094693e47a6d08"
  }
}

inputs = {
  environment = local.env.environment
  name        = "capstone-prod-nlb"
  vpc_id      = dependency.vpc.outputs.vpc_id

  subnet_mappings = {
    "public-a" = {
      subnet_id     = dependency.subnets.outputs.subnet_ids["public-subnet-a"]
      allocation_id = "eipalloc-0d15b229ba2bd69b7"
    }
  }

  target_groups = {
    "capstone-prod-alb-tg" = {
      port                               = 80
      protocol                           = "TCP"
      target_type                        = "alb"
      deregistration_delay               = 300
      lambda_multi_value_headers_enabled = false
      proxy_protocol_v2                  = false
      slow_start                         = 0
      health_check_port                  = "traffic-port"
      health_check_path                  = "/"
      healthy_threshold                  = 5
      unhealthy_threshold                = 2
      interval                           = 30
      health_check_timeout               = 6
      matcher                            = "200-399"
      deregistration_delay               = 300
      lambda_multi_value_headers_enabled = false
      proxy_protocol_v2                  = false
      slow_start                         = 0
    }
  }

  target_group_attachments = {
    alb = {
      target_group_key = "capstone-prod-alb-tg"
      target_id        = dependency.alb.outputs.alb_arn
    }
  }

  listeners = {
    tcp = {
      port             = 80
      protocol         = "TCP"
      target_group_key = "capstone-prod-alb-tg"
      forward = {
        target_groups = [{ weight = 0 }]
        stickiness = {
          enabled  = false
          duration = 1
        }
      }
    }
  }
}
