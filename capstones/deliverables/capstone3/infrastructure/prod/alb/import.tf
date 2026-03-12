import {
  to = aws_lb.this
  id = "arn:aws:elasticloadbalancing:us-east-1:285233622389:loadbalancer/app/capstone-prod-alb/0e997dfad23ae304"
}

import {
  to = aws_lb_target_group.this["capstone-prod-ec2-tg"]
  id = "arn:aws:elasticloadbalancing:us-east-1:285233622389:targetgroup/capstone-prod-ec2-tg/15e7e9dccf6610d3"
}

import {
  to = aws_lb_listener.this["http"]
  id = "arn:aws:elasticloadbalancing:us-east-1:285233622389:listener/app/capstone-prod-alb/0e997dfad23ae304/c2c5bd81e01ac461"
}

import {
  to = aws_lb_target_group_attachment.this["web"]
  id = "arn:aws:elasticloadbalancing:us-east-1:285233622389:targetgroup/capstone-prod-ec2-tg/15e7e9dccf6610d3,i-0201e0778e1cd43e9"
}
