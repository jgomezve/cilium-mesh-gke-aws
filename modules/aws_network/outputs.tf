output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "private_subnets_id" {
  value = [for subnet in aws_subnet.private_subnet : subnet.id]
}