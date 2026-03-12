import {
  to = aws_security_group.this["alb"]
  id = "sg-0f8ba3ec56840a5b7"
}

import {
  to = aws_security_group.this["ec2"]
  id = "sg-0851f8a754a786298"
}

import {
  to = aws_vpc_security_group_ingress_rule.this["alb-ingress-0"]
  id = "sgr-06d446bf278901405"
}

import {
  to = aws_vpc_security_group_ingress_rule.this["ec2-ingress-0"]
  id = "sgr-07d0f47713450453a"
}

import {
  to = aws_vpc_security_group_ingress_rule.this["ec2-ingress-1"]
  id = "sgr-0e6d296adfc691e77"
}

import {
  to = aws_vpc_security_group_egress_rule.all["alb"]
  id = "sgr-0f282e1144731503b"
}

import {
  to = aws_vpc_security_group_egress_rule.all["ec2"]
  id = "sgr-0a2546b096090cce7"
}
