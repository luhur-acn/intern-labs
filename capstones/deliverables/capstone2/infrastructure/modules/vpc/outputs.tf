output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "List of IDs of public subnets"
  value       = values(aws_subnet.public)[*].id
}

output "private_subnet_ids" {
  description = "List of IDs of private subnets"
  value       = values(aws_subnet.private)[*].id
}

output "public_rt_id" {
  description = "The ID of the public route table"
  value       = aws_route_table.public.id
}

output "private_rt_id" {
  description = "The ID of the private route table"
  value       = aws_route_table.private.id
}
