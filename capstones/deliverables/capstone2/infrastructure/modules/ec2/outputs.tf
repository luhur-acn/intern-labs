output "instance_ids" {
  description = "Map of instance IDs keyed by the same keys as the input map"
  value       = { for k, inst in aws_instance.this : k => inst.id }
}

output "private_ips" {
  description = "Map of private IPs keyed by the same keys as the input map"
  value       = { for k, inst in aws_instance.this : k => inst.private_ip }
}

output "iam_role_arn" {
  description = "The ARN of the shared IAM role"
  value       = aws_iam_role.this.arn
}

output "iam_role_name" {
  description = "The name of the shared IAM role"
  value       = aws_iam_role.this.name
}
