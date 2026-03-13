locals {
  environment          = "prod"
  vpc_cidr             = "10.1.0.0/16"
  public_subnet_cidrs  = ["10.1.1.0/24", "10.1.3.0/24", "10.1.5.0/24"]
  private_subnet_cidrs = ["10.1.2.0/24", "10.1.4.0/24", "10.1.6.0/24"]
  availability_zones   = ["us-east-1a", "us-east-1b", "us-east-1c"]
  ami_id               = "ami-0c02fb55956c7d316"
}
