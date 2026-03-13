# infrastructure/dev/env.hcl
locals {
  environment = "dev"
  vpc_cidr    = "10.0.0.0/16"
  ami_id      = "ami-0c02fb55956c7d316"
}
