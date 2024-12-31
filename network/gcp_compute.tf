
resource "google_compute_firewall" "default_rules" {
  name    = "default-rules"
  network = google_compute_network.gke_vpc.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  allow {
    protocol = "tcp"
    ports    = ["80", "8080", "1000-2000"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_instance" "default" {
  name         = "test-vm"
  machine_type = "e2-micro"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }
  network_interface {
    network    = google_compute_network.gke_vpc.id
    subnetwork = google_compute_subnetwork.gke_nodes_subnet.id
  }

  lifecycle {
    ignore_changes = [
      metadata["ssh-keys"]
    ]
  }
}