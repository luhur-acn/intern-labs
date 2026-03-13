import {
  to = aws_lb.this
  id = "arn:aws:elasticloadbalancing:us-east-1:711784092484:loadbalancer/net/capstone-dev-nlb/70b5d50d5751348f"
}

import {
  to = aws_lb_target_group.this["capstone-dev-alb-tg"]
  id = "arn:aws:elasticloadbalancing:us-east-1:711784092484:targetgroup/capstone-dev-alb-tg/5f86bcb62aef3a43"
}

import {
  to = aws_lb_listener.this["tcp"]
  id = "arn:aws:elasticloadbalancing:us-east-1:711784092484:listener/net/capstone-dev-nlb/70b5d50d5751348f/ad15520f23168471"
}

import {
  to = aws_lb_target_group_attachment.this["alb"]
  id = "arn:aws:elasticloadbalancing:us-east-1:711784092484:targetgroup/capstone-dev-alb-tg/5f86bcb62aef3a43,arn:aws:elasticloadbalancing:us-east-1:711784092484:loadbalancer/app/capstone-dev-alb/c064f12a2c4e09a7"
}
