# modules/ec2/outputs.tf
output "instance_ids" {
  value = { for k, inst in aws_instance.this : k => inst.id }
}
output "private_ips" {
  value = { for k, inst in aws_instance.this : k => inst.private_ip }
}
# output "iam_role_arn" { value = aws_iam_role.this.arn }
