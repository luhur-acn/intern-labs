import {
  to = aws_lb.this
  id = "arn:aws:elasticloadbalancing:us-east-1:711784092484:loadbalancer/app/capstone-prod-alb/8507f240dde92351"
}

import {
  to = aws_lb_target_group.this["capstone-prod-ec2-tg"]
  id = "arn:aws:elasticloadbalancing:us-east-1:711784092484:targetgroup/capstone-prod-ec2-tg/d57e656f480ec33f"
}

import {
  to = aws_lb_listener.this["http"]
  id = "arn:aws:elasticloadbalancing:us-east-1:711784092484:listener/app/capstone-prod-alb/8507f240dde92351/3b90f2335e298a1a"
}

import {
  to = aws_lb_target_group_attachment.this["web"]
  id = "arn:aws:elasticloadbalancing:us-east-1:711784092484:targetgroup/capstone-prod-ec2-tg/d57e656f480ec33f,i-00ff6e641d3f555b2,80"
}
