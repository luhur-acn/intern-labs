import {
  to = aws_security_group.this["alb"]
  id = "sg-09e720415485ee5c6"
}

import {
  to = aws_security_group.this["ec2"]
  id = "sg-0a2d160549d6a22bd"
}

import {
  to = aws_vpc_security_group_ingress_rule.this["alb-ingress-0"]
  id = "sgr-0a33a1536ab311ea7"
}

import {
  to = aws_vpc_security_group_ingress_rule.this["ec2-ingress-0"]
  id = "sgr-00f4410323fc67ac3"
}

import {
  to = aws_vpc_security_group_ingress_rule.this["ec2-ingress-1"]
  id = "sgr-0c98078d0e72195c8"
}

import {
  to = aws_vpc_security_group_egress_rule.all["alb"]
  id = "sgr-05edfd108a54673d4"
}

import {
  to = aws_vpc_security_group_egress_rule.all["ec2"]
  id = "sgr-0b0328074ca54afdf"
}
