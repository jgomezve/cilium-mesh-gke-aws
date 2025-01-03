resource "google_compute_network" "vpc" {
  name                    = var.name
  auto_create_subnetworks = var.vpc_auto_mode
}

resource "google_compute_subnetwork" "gke_nodes_subnet" {
  for_each      = { for subnet in var.private_subnets : subnet.cidr => subnet }
  name          = replace(replace("${var.name}--${each.value.cidr}", "/", "-"), ".", "--")
  ip_cidr_range = each.value.cidr
  region        = each.value.region
  network       = google_compute_network.vpc.id
}

resource "google_compute_router" "router" {
  count   = var.internet_access ? 1 : 0
  name    = "router-${var.name}"
  region  = var.region
  network = google_compute_network.vpc.id
}

resource "google_compute_router_nat" "nat" {
  count                              = var.internet_access ? 1 : 0
  name                               = "nat-${var.name}"
  router                             = google_compute_router.router[0].name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = var.nat_network_options

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}