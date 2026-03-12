import {
  to = aws_lb.this
  id = "arn:aws:elasticloadbalancing:us-east-1:285233622389:loadbalancer/net/capstone-prod-nlb/82402594ab2649b3"
}

import {
  to = aws_lb_target_group.this["capstone-prod-alb-tg"]
  id = "arn:aws:elasticloadbalancing:us-east-1:285233622389:targetgroup/capstone-prod-alb-tg/a7ca77861829b95d"
}

import {
  to = aws_lb_listener.this["tcp"]
  id = "arn:aws:elasticloadbalancing:us-east-1:285233622389:listener/net/capstone-prod-nlb/82402594ab2649b3/0161e1b38f089dca"
}

import {
  to = aws_lb_target_group_attachment.this["alb"]
  id = "arn:aws:elasticloadbalancing:us-east-1:285233622389:targetgroup/capstone-prod-alb-tg/a7ca77861829b95d,arn:aws:elasticloadbalancing:us-east-1:285233622389:loadbalancer/app/capstone-prod-alb/0e997dfad23ae304"
}
