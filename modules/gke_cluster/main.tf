#TODO: FW rules on the vpc?

resource "google_container_cluster" "cluster" {
  name                     = var.name
  deletion_protection      = false
  location                 = var.location
  network                  = var.gke_vpc_id
  subnetwork               = var.gke_subnet_id
  remove_default_node_pool = true
  initial_node_count       = 1
  cluster_ipv4_cidr        = var.pod_cidr

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

resource "google_container_node_pool" "node_group" {
  name       = "${var.name}-nodes"
  location   = var.location
  cluster    = google_container_cluster.cluster.name
  node_count = 1

  node_config {
    preemptible  = true
    machine_type = var.nodes_type
    disk_size_gb = 50
  }

  autoscaling {
    min_node_count = var.maximum_nodes
    max_node_count = var.maximum_nodes
  }

  network_config {
    enable_private_nodes = var.private_cluser
  }
}