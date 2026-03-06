provider "aws" {
  region = "us-east-1"
}

module "vpc_test" {
  source               = "../../modules/vpc"
  vpc_cidr             = "10.99.0.0/16"
  public_subnet_cidrs  = ["10.99.1.0/24", "10.99.3.0/24", "10.99.5.0/24"]
  private_subnet_cidrs = ["10.99.2.0/24", "10.99.4.0/24", "10.99.6.0/24"]
  availability_zones   = ["us-east-1a", "us-east-1b", "us-east-1c"]
  environment          = "test"
  region               = "us-east-1"
}

output "vpc_id" {
  value = module.vpc_test.vpc_id
}
