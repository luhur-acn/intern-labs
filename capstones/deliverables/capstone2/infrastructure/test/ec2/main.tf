provider "aws" {
  region = "us-east-1"
}

module "ec2_test" {
  source      = "../../modules/ec2"
  environment = "test"
  instances = {
    web = {
      ami_id             = "ami-0c02fb55956c7d316"
      instance_type      = "t3.micro"
      subnet_id          = "subnet-12345678" # Mock Subnet ID
      security_group_ids = ["sg-12345678"]   # Mock SG ID
      user_data          = "echo hello"
    }
  }
}

output "instance_ids" {
  value = module.ec2_test.instance_ids
}
