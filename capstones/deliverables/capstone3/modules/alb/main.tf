# modules/alb/main.tf
resource "aws_lb" "this" {
  name               = var.name
  internal           = false
  load_balancer_type = "application"
  security_groups    = var.security_group_ids
  subnets            = var.subnet_ids

  tags = var.tags
}

resource "aws_lb_target_group" "this" {
  for_each = var.target_groups

  name                               = each.key
  port                               = each.value.port
  protocol                           = each.value.protocol
  vpc_id                             = var.vpc_id
  target_type                        = each.value.target_type
  proxy_protocol_v2                  = each.value.proxy_protocol_v2
  load_balancing_algorithm_type      = each.value.load_balancing_algorithm_type
  load_balancing_anomaly_mitigation  = each.value.load_balancing_anomaly_mitigation
  load_balancing_cross_zone_enabled  = each.value.load_balancing_cross_zone_enabled
  lambda_multi_value_headers_enabled = each.value.lambda_multi_value_headers_enabled

  health_check {
    path                = each.value.health_check_path
    healthy_threshold   = each.value.healthy_threshold
    unhealthy_threshold = each.value.unhealthy_threshold
    interval            = each.value.interval
    timeout             = each.value.timeout
    matcher             = each.value.matcher
  }

  tags = var.tags
}

resource "aws_lb_target_group_attachment" "this" {
  for_each = var.target_group_attachments

  target_group_arn = aws_lb_target_group.this[each.value.target_group_key].arn
  target_id        = each.value.target_id
  port             = each.value.port
}

resource "aws_lb_listener" "this" {
  for_each = var.listeners

  load_balancer_arn = aws_lb.this.arn
  port              = each.value.port
  protocol          = each.value.protocol

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[each.value.target_group_key].arn
  }

  lifecycle {
    ignore_changes = [default_action[0].forward]
  }

  tags = var.tags
}
