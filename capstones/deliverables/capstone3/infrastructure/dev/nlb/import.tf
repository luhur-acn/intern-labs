import {
  to = aws_lb.this
  id = "arn:aws:elasticloadbalancing:us-east-1:285233622389:loadbalancer/net/capstone-dev-nlb/c04062ccee47492d"
}

import {
  to = aws_lb_target_group.this["capstone-dev-alb-tg"]
  id = "arn:aws:elasticloadbalancing:us-east-1:285233622389:targetgroup/capstone-dev-alb-tg/791d11854fdadf15"
}

import {
  to = aws_lb_listener.this["tcp"]
  id = "arn:aws:elasticloadbalancing:us-east-1:285233622389:listener/net/capstone-dev-nlb/c04062ccee47492d/822b4302aeafa54c"
}

import {
  to = aws_lb_target_group_attachment.this["alb"]
  id = "arn:aws:elasticloadbalancing:us-east-1:285233622389:targetgroup/capstone-dev-alb-tg/791d11854fdadf15,arn:aws:elasticloadbalancing:us-east-1:285233622389:loadbalancer/app/capstone-dev-alb/bbb3cd3c193237ad"
}
