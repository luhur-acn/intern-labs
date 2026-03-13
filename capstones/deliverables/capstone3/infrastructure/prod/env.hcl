# infrastructure/prod/env.hcl
locals {
  environment = "prod"
  vpc_cidr    = "10.1.0.0/16"
  ami_id      = "ami-0c02fb55956c7d316"
}
