provider "aws" {
  region = "us-east-1"
}

module "sg_test" {
  source      = "../../modules/security-groups"
  vpc_id      = "vpc-12345678" # Mock VPC ID for validation
  environment = "test"
  security_groups = {
    ec2 = {
      description = "EC2 instances"
      ingress_rules = [
        { description = "SSH", from_port = 22, to_port = 22, ip_protocol = "tcp", cidr_ipv4 = "10.0.0.0/8" },
        { description = "HTTP", from_port = 80, to_port = 80, ip_protocol = "tcp", cidr_ipv4 = "0.0.0.0/0" },
      ]
      egress_rules = [
        { description = "Allow all outbound", from_port = 0, to_port = 65535, ip_protocol = "tcp", cidr_ipv4 = "0.0.0.0/0" }
      ]
    }
    alb = {
      description = "Load balancer"
      ingress_rules = [
        { description = "HTTP", from_port = 80, to_port = 80, ip_protocol = "tcp", cidr_ipv4 = "0.0.0.0/0" },
      ]
      egress_rules = [
        { description = "Allow all outbound", from_port = 0, to_port = 65535, ip_protocol = "tcp", cidr_ipv4 = "0.0.0.0/0" }
      ]
    }
  }
}

output "sg_ids" {
  value = module.sg_test.security_group_ids
}
