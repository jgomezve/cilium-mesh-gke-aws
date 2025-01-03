provider "google" {
  project = "gke-cilium-443902"
  region  = "us-central1"
  zone    = "us-central1-a"
}

data "google_compute_network" "gke_cluster" {
  name = "gke-cluster"
}
data "google_compute_subnetwork" "gke_nodes" {
  name   = "gke-nodes"
  region = "us-central1"
}

resource "google_container_cluster" "gke_cluster" {
  name = "gke-cilium"
  deletion_protection = false

  location = "us-central1-a"

  network    = data.google_compute_network.gke_cluster.id
  subnetwork = data.google_compute_subnetwork.gke_nodes.id

  remove_default_node_pool = true
  initial_node_count       = 1

  cluster_ipv4_cidr = "10.111.0.0/16"

  addons_config {
    gce_persistent_disk_csi_driver_config {
        enabled = false
    }
  }

  monitoring_config {
    managed_prometheus {
      enabled = false
    }
  }
}

resource "google_container_node_pool" "gke_nodes" {
  name       = "gke-cililum-nodes"
  location   = "us-central1-a"
  cluster    = google_container_cluster.gke_cluster.name
  node_count = 1

  node_config {
    preemptible  = true
    machine_type = "e2-small"
    disk_size_gb = 50
  }

 autoscaling {
    min_node_count = 1
    max_node_count = 1
  }

  network_config {
    enable_private_nodes = true
  }
}