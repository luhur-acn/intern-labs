import {
  to = aws_security_group.this["alb"]
  id = "sg-0f51d8db5eb9f3f6f"
}

import {
  to = aws_security_group.this["ec2"]
  id = "sg-065265d8b0ddd554f"
}

import {
  to = aws_vpc_security_group_ingress_rule.this["alb-ingress-0"]
  id = "sgr-0f486617292bbea04"
}

import {
  to = aws_vpc_security_group_ingress_rule.this["ec2-ingress-0"]
  id = "sgr-031932be2a8269fd6"
}

import {
  to = aws_vpc_security_group_ingress_rule.this["ec2-ingress-1"]
  id = "sgr-0538274af1e68531d"
}

import {
  to = aws_vpc_security_group_egress_rule.all["alb"]
  id = "sgr-0afa5d2012bbbc759"
}

import {
  to = aws_vpc_security_group_egress_rule.all["ec2"]
  id = "sgr-05ca2814fd6dc482b"
}
