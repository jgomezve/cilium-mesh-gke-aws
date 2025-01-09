data "google_compute_network" "gcp_vpc" {
  name = var.gcp_vpc_name
}

data "aws_vpc" "aws_vpc" {
  filter {
    name   = "tag:Name"
    values = [var.aws_vpc_name]
  }
}

resource "aws_vpn_gateway" "vpn_gw" {
  vpc_id = data.aws_vpc.aws_vpc.id

  tags = {
    Name = "VPN GW ${var.name}"
  }
}

resource "google_compute_address" "external_ip_vpn" {
  name         = "external-ip-${var.name}"
  address_type = "EXTERNAL"
  region       = var.region
}

resource "google_compute_vpn_gateway" "vpn_gw" {
  name    = "vpn-gw-${var.name}"
  network = data.google_compute_network.gcp_vpc.id
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
  tunnel1_ike_versions = ["ikev${var.ike_version}"]

  static_routes_only = true

  tags = {
    Name = "Connection ${var.name}"
  }
}

resource "aws_vpn_connection_route" "route_to_gcp" {
  vpn_connection_id      = aws_vpn_connection.vpn_connection.id
  destination_cidr_block = var.cidr_gcp
}

resource "aws_vpn_gateway_route_propagation" "route_propagation" {
  #for_each       = tomap({ for idx, id in var.aws_route_tables_ids : idx => id })
  for_each       = toset([for i in range(length(var.aws_route_tables_ids)) : tostring(i)])
  vpn_gateway_id = aws_vpn_gateway.vpn_gw.id
  route_table_id = var.aws_route_tables_ids[each.key]
}

resource "google_compute_forwarding_rule" "rule" {
  for_each    = { for rule in var.gcp_forwarding_rules : "${rule.protocol}-${rule.port}" => rule }
  name        = lower("fr-${each.value.protocol}${each.value.port}")
  ip_protocol = each.value.protocol
  port_range  = each.value.port
  ip_address  = google_compute_address.external_ip_vpn.address
  target      = google_compute_vpn_gateway.vpn_gw.id
}


resource "google_compute_vpn_tunnel" "tunnel" {
  count         = 2
  name          = "tunnel${count.index + 1}"
  peer_ip       = count.index == 0 ? aws_vpn_connection.vpn_connection.tunnel1_address : aws_vpn_connection.vpn_connection.tunnel2_address
  shared_secret = count.index == 0 ? aws_vpn_connection.vpn_connection.tunnel1_preshared_key : aws_vpn_connection.vpn_connection.tunnel2_preshared_key

  target_vpn_gateway = google_compute_vpn_gateway.vpn_gw.id
  ike_version        = var.ike_version

  remote_traffic_selector = [var.cidr_aws]
  local_traffic_selector  = ["0.0.0.0"]
  depends_on = [
    google_compute_forwarding_rule.rule
  ]
}

resource "google_compute_route" "route_aws" {
  count      = 2
  name       = "route-${var.name}-${count.index + 1}"
  network    = var.gcp_vpc_name
  dest_range = var.cidr_aws
  priority   = 1000

  next_hop_vpn_tunnel = count.index == 0 ? google_compute_vpn_tunnel.tunnel[0].id : google_compute_vpn_tunnel.tunnel[1].id
}
