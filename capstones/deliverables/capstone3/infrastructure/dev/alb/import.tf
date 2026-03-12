import {
  to = aws_lb.this
  id = "arn:aws:elasticloadbalancing:us-east-1:285233622389:loadbalancer/app/capstone-dev-alb/bbb3cd3c193237ad"
}

import {
  to = aws_lb_target_group.this["capstone-dev-ec2-tg"]
  id = "arn:aws:elasticloadbalancing:us-east-1:285233622389:targetgroup/capstone-dev-ec2-tg/d7d2707251ae0843"
}

import {
  to = aws_lb_listener.this["http"]
  id = "arn:aws:elasticloadbalancing:us-east-1:285233622389:listener/app/capstone-dev-alb/bbb3cd3c193237ad/43e5f74f3f765dfe"
}

# Real target attachment ID format: TG_ARN,TARGET_ID
import {
  to = aws_lb_target_group_attachment.this["web"]
  id = "arn:aws:elasticloadbalancing:us-east-1:285233622389:targetgroup/capstone-dev-ec2-tg/d7d2707251ae0843,i-0adda7eb7a021b853"
}
