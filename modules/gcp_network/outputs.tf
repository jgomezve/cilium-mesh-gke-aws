output "vpc_id" {
  value = google_compute_network.vpc.id
}

output "private_subnets_id" {
  value = [for subnet in google_compute_subnetwork.gke_nodes_subnet : subnet.id]
}