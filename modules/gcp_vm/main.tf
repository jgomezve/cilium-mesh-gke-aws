
resource "google_compute_firewall" "default_rules" {
  name    = "default-rules"
  network = var.vpc_name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_instance" "default" {
  name         = var.name
  machine_type = var.vm_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }
  network_interface {
    network    = var.vpc_id
    subnetwork = var.subnet_id
  }

  lifecycle {
    ignore_changes = [
      metadata["ssh-keys"]
    ]
  }
}