import {
  to = aws_lb.this
  id = "arn:aws:elasticloadbalancing:us-east-1:711784092484:loadbalancer/app/capstone-dev-alb/c064f12a2c4e09a7"
}

import {
  to = aws_lb_target_group.this["capstone-dev-ec2-tg"]
  id = "arn:aws:elasticloadbalancing:us-east-1:711784092484:targetgroup/capstone-dev-ec2-tg/6e8539b93454898f"
}

import {
  to = aws_lb_listener.this["http"]
  id = "arn:aws:elasticloadbalancing:us-east-1:711784092484:listener/app/capstone-dev-alb/c064f12a2c4e09a7/ab3f7556a505f6a6"
}

# Real target attachment ID format: TG_ARN,TARGET_ID
import {
  to = aws_lb_target_group_attachment.this["web"]
  id = "arn:aws:elasticloadbalancing:us-east-1:711784092484:targetgroup/capstone-dev-ec2-tg/6e8539b93454898f,i-009b9586f5a73f812,80"
}
