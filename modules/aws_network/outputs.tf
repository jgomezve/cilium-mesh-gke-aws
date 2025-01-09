output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.vpc.id
}

output "vpc_name" {
  description = "VPC Name"
  value       = var.name
}

output "private_subnets_id" {
  description = "List of ID of the private subnets"
  value       = [for subnet in aws_subnet.private_subnet : subnet.id]
}

output "private_subnets_id_eks_enabled" {
  description = "List of ID of the private subnets enabled for EKS"
  value       = [for subnet in aws_subnet.private_subnet : subnet.id if subnet.tags["kubernetes.io/role/internal-elb"] == "1"]
}

output "private_route_tables_id" {
  description = "List of ID of the private route-tables"
  value       = [for route_table in aws_route_table.route_table_private_subnet : route_table.id]
}