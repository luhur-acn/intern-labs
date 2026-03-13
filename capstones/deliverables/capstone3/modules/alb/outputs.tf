# modules/alb/outputs.tf
output "alb_arn" { value = aws_lb.this.arn }
output "alb_dns" { value = aws_lb.this.dns_name }
output "target_group_arns" {
  value = { for k, tg in aws_lb_target_group.this : k => tg.arn }
}
output "listener_arns" {
  value = { for k, l in aws_lb_listener.this : k => l.arn }
}
