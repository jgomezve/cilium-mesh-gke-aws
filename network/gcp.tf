provider "google" {
  project = "gke-cilium-443902"
  region  = "us-central1"
  zone    = "us-central1-a"
}

resource "google_compute_network" "gke_vpc" {
  name                    = "gke-cluster"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "gke_nodes_subnet" {
  name          = "gke-nodes"
  ip_cidr_range = "192.168.1.0/24"
  region        = "us-central1"
  network       = google_compute_network.gke_vpc.id
}

resource "google_compute_address" "external_ip_vpn" {
  name         = "gke-external-ip"
  address_type = "EXTERNAL"
  region       = "us-central1"
}

resource "google_compute_vpn_gateway" "gw_gke" {
  name    = "vpn-gke"
  network = google_compute_network.gke_vpc.id
}

resource "google_compute_forwarding_rule" "fr_esp" {
  name        = "fr-esp"
  ip_protocol = "ESP"
  ip_address  = google_compute_address.external_ip_vpn.address
  target      = google_compute_vpn_gateway.gw_gke.id
}

resource "google_compute_forwarding_rule" "fr_udp4500" {
  name        = "fr-udp4500"
  ip_protocol = "UDP"
  port_range  = "4500"
  ip_address  = google_compute_address.external_ip_vpn.address
  target      = google_compute_vpn_gateway.gw_gke.id
}

resource "google_compute_forwarding_rule" "fr_udp500" {
  name        = "fr-udp500"
  ip_protocol = "UDP"
  port_range  = "500"
  ip_address  = google_compute_address.external_ip_vpn.address
  target      = google_compute_vpn_gateway.gw_gke.id
}

resource "google_compute_vpn_tunnel" "gke_tunnel_1" {
  name          = "tunnel1"
  peer_ip       = aws_vpn_connection.vpn_connection.tunnel1_address
  shared_secret = aws_vpn_connection.vpn_connection.tunnel1_preshared_key

  target_vpn_gateway = google_compute_vpn_gateway.gw_gke.id
  ike_version        = 1

  remote_traffic_selector = ["172.16.0.0/16"]
  local_traffic_selector  = ["0.0.0.0"]
  depends_on = [
    google_compute_forwarding_rule.fr_esp,
    google_compute_forwarding_rule.fr_udp500,
    google_compute_forwarding_rule.fr_udp4500,
  ]
}

resource "google_compute_vpn_tunnel" "gke_tunnel_2" {
  name          = "tunnel2"
  peer_ip       = aws_vpn_connection.vpn_connection.tunnel2_address
  shared_secret = aws_vpn_connection.vpn_connection.tunnel2_preshared_key

  target_vpn_gateway = google_compute_vpn_gateway.gw_gke.id
  ike_version        = 1

  remote_traffic_selector = ["172.16.0.0/16"]
  local_traffic_selector  = ["0.0.0.0"]
  depends_on = [
    google_compute_forwarding_rule.fr_esp,
    google_compute_forwarding_rule.fr_udp500,
    google_compute_forwarding_rule.fr_udp4500,
  ]
}


resource "google_compute_route" "this" {
  name       = "the-route"
  network    = google_compute_network.gke_vpc.name
  dest_range = "172.16.0.0/16"
  priority   = 1000

  next_hop_vpn_tunnel = google_compute_vpn_tunnel.gke_tunnel_1.id
}