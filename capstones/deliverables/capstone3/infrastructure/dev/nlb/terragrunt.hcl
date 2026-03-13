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
    subnet_ids = { "public-subnet-a" = "subnet-00ee23fa766d6da69" }
  }
}

dependency "alb" {
  config_path = "../alb"
  mock_outputs = {
    alb_arn = "arn:aws:elasticloadbalancing:us-east-1:281762848670:loadbalancer/app/capstone-dev-alb/908e32a9d7f2b32b"
  }
}

dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = {
    vpc_id = "vpc-0f1979d478dd0ae39"
  }
}

inputs = {
  environment = local.env.environment
  name        = "capstone-dev-nlb"
  vpc_id      = dependency.vpc.outputs.vpc_id

  subnet_mappings = {
    "public-a" = {
      subnet_id     = dependency.subnets.outputs.subnet_ids["public-subnet-a"]
      allocation_id = "eipalloc-0d2b267d77451c58c"
    }
  }

  target_groups = {
    "capstone-dev-alb-tg" = {
      port                               = 80
      protocol                           = "TCP"
      target_type                        = "alb"
      health_check_port                  = "traffic-port"
      health_check_path                  = "/"
      healthy_threshold                  = 5
      unhealthy_threshold                = 2
      interval                           = 30
      health_check_timeout               = 6
      matcher                            = "200-399"
    }
  }

  target_group_attachments = {
    alb = {
      target_group_key = "capstone-dev-alb-tg"
      target_id        = dependency.alb.outputs.alb_arn
    }
  }

  listeners = {
    tcp = {
      port             = 80
      protocol         = "TCP"
      target_group_key = "capstone-dev-alb-tg"
      forward = {
        target_groups = [{ weight = 0 }]
        # stickiness = {
        #   enabled  = false
        #   duration = 0
        # }
      }
    }
  }
}
