module "gke_cluster" {
  source        = ".."
  name          = "gke-cluster"
  pod_cidr      = "10.111.0.0/16"
  gke_vpc_id    = google_compute_network.vpc.id
  gke_subnet_id = google_compute_subnetwork.subnet.id
  location      = "us-central1-a"
}