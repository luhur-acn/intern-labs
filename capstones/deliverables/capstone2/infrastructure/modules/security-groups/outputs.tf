output "security_group_ids" {
  description = "Map of Security Group IDs keyed by the same keys as the input map"
  value       = { for k, sg in aws_security_group.this : k => sg.id }
}
