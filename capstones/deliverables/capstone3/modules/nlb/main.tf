resource "aws_lb" "this" {
  name               = var.name
  internal           = false
  load_balancer_type = "network"

  dynamic "subnet_mapping" {
    for_each = var.subnet_mappings
    content {
      subnet_id     = subnet_mapping.value.subnet_id
      allocation_id = subnet_mapping.value.allocation_id
    }
  }

  tags = var.tags
}

resource "aws_lb_target_group" "this" {
  for_each = var.target_groups

  name        = each.key
  port        = each.value.port
  protocol    = each.value.protocol
  vpc_id      = var.vpc_id
  target_type = each.value.target_type

  deregistration_delay               = each.value.deregistration_delay
  proxy_protocol_v2                  = each.value.proxy_protocol_v2
  lambda_multi_value_headers_enabled = each.value.lambda_multi_value_headers_enabled
  slow_start                         = each.value.slow_start

  health_check {
    enabled             = true
    protocol            = each.value.health_check_protocol
    port                = each.value.health_check_port
    path                = each.value.health_check_path
    interval            = each.value.health_check_interval
    timeout             = each.value.health_check_timeout
    healthy_threshold   = each.value.healthy_threshold
    unhealthy_threshold = each.value.unhealthy_threshold
    matcher             = each.value.matcher
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [
      deregistration_delay,
      proxy_protocol_v2,
      lambda_multi_value_headers_enabled,
      slow_start,
      stickiness
    ]
  }
}

resource "aws_lb_target_group_attachment" "this" {
  for_each = var.target_group_attachments

  target_group_arn = aws_lb_target_group.this[each.value.target_group_key].arn
  target_id        = each.value.target_id
}

resource "aws_lb_listener" "this" {
  for_each = var.listeners

  load_balancer_arn = aws_lb.this.arn
  port              = each.value.port
  protocol          = each.value.protocol

  default_action {
    type             = "forward"
    target_group_arn = each.value.forward == null ? aws_lb_target_group.this[each.value.target_group_key].arn : null

    dynamic "forward" {
      for_each = each.value.forward != null ? [each.value.forward] : []
      content {
        target_group {
          arn    = aws_lb_target_group.this[each.value.target_group_key].arn
          weight = try(forward.value.target_groups[0].weight, 1)
        }

        dynamic "stickiness" {
          for_each = forward.value.stickiness != null ? [forward.value.stickiness] : []
          content {
            enabled  = stickiness.value.enabled
            duration = stickiness.value.duration
          }
        }
      }
    }

  }

  lifecycle {
    ignore_changes = [
      default_action[0].target_group_arn,
      default_action[0].forward
    ]
  }

  tags = var.tags
}
