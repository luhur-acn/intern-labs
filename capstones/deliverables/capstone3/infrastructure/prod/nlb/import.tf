import {
  to = aws_lb.this
  id = "arn:aws:elasticloadbalancing:us-east-1:711784092484:loadbalancer/net/capstone-prod-nlb/12d784292335dccc"
}

import {
  to = aws_lb_target_group.this["capstone-prod-alb-tg"]
  id = "arn:aws:elasticloadbalancing:us-east-1:711784092484:targetgroup/capstone-prod-alb-tg/41bd1d9e5ef8bb52"
}

import {
  to = aws_lb_listener.this["tcp"]
  id = "arn:aws:elasticloadbalancing:us-east-1:711784092484:listener/net/capstone-prod-nlb/12d784292335dccc/500ce664b08fce31"
}

import {
  to = aws_lb_target_group_attachment.this["alb"]
  id = "arn:aws:elasticloadbalancing:us-east-1:711784092484:targetgroup/capstone-prod-alb-tg/41bd1d9e5ef8bb52,arn:aws:elasticloadbalancing:us-east-1:711784092484:loadbalancer/app/capstone-prod-alb/8507f240dde92351"
}
