
resource "aws_vpn_gateway" "vpn_gw" {
  vpc_id = var.vpc_id

  tags = {
    Name = "VPN GW ${var.name}"
  }
}

resource "google_compute_address" "external_ip_vpn" {
  name         = "External IP ${var.name}"
  address_type = "EXTERNAL"
  region       = var.region
}

resource "google_compute_vpn_gateway" "vpn_gw" {
  name    = "VPN GW ${var.name}"
  network = var.vpc_id
}

resource "aws_customer_gateway" "remote_site" {
  bgp_asn    = var.bgp_asn
  ip_address = google_compute_address.external_ip_vpn.address
  type       = "ipsec.1"

  tags = {
    Name = "GCP Remote (${var.name})"
  }
}

resource "aws_vpn_connection" "vpn_connection" {
  vpn_gateway_id       = aws_vpn_gateway.vpn_gw.id
  customer_gateway_id  = aws_customer_gateway.remote_site.id
  type                 = "ipsec.1"
  tunnel1_ike_versions = ["ikev1"]

  static_routes_only = true

  tags = {
    Name = "Connection ${var.name}"
  }
}

resource "aws_vpn_connection_route" "route_to_gcp" {
  vpn_connection_id      = aws_vpn_connection.vpn_connection.id
  destination_cidr_block = "192.168.1.0/24"
}