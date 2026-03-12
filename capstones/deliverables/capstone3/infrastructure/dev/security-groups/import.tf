import {
  to = aws_security_group.this["alb"]
  id = "sg-0363744fea1101c64"
}

import {
  to = aws_security_group.this["ec2"]
  id = "sg-0b80560efd093f0b6"
}

import {
  to = aws_vpc_security_group_ingress_rule.this["alb-ingress-0"]
  id = "sgr-006f78db7bb59e0e1"
}

import {
  to = aws_vpc_security_group_ingress_rule.this["ec2-ingress-0"]
  id = "sgr-0112a485ae38ecf5d"
}

import {
  to = aws_vpc_security_group_ingress_rule.this["ec2-ingress-1"]
  id = "sgr-0839d3ff0e33a70d4"
}

import {
  to = aws_vpc_security_group_egress_rule.all["alb"]
  id = "sgr-04ae88cd7f310ca0f"
}

import {
  to = aws_vpc_security_group_egress_rule.all["ec2"]
  id = "sgr-041ca172d77283009"
}
