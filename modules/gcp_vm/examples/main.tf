module "gcp_vm_tshoot" {
  source    = ".."
  name      = "test-vm"
  vpc_name  = google_compute_network.vpc.name
  vpc_id    = google_compute_network.vpc.id
  subnet_id = google_compute_subnetwork.subnet.id
  zone      = "us-central1-a"
}
