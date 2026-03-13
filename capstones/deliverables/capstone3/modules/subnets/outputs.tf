# modules/subnets/outputs.tf
output "subnet_ids" {
  value = { for k, s in aws_subnet.this : k => s.id }
}
output "public_subnet_ids" {
  value = [for k, s in aws_subnet.this : s.id if var.subnets[k].tier == "public"]
}
output "private_subnet_ids" {
  value = [for k, s in aws_subnet.this : s.id if var.subnets[k].tier == "private"]
}
output "nat_gateway_id" { value = aws_nat_gateway.this.id }
output "public_rt_id" { value = aws_route_table.public.id }
output "private_rt_id" { value = aws_route_table.private.id }
