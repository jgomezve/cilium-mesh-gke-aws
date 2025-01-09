output "vpc_id" {
  description = "VPC ID"
  value       = google_compute_network.vpc.id
}

output "vpc_name" {
  description = "VPC Name"
  value       = google_compute_network.vpc.name
}

output "private_subnets_id" {
  description = "List of IDs of private subnets"
  value       = [for subnet in google_compute_subnetwork.gke_nodes_subnet : subnet.id]
}