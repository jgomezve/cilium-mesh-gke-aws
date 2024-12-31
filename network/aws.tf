provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "eks_cluster" {
  cidr_block           = "172.16.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "eks_cluster"
  }
}

resource "aws_subnet" "eks_nodes" {
  vpc_id            = aws_vpc.eks_cluster.id
  cidr_block        = "172.16.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "eks_nodes"
  }
}

resource "aws_subnet" "eks_nodes_2" {
  vpc_id            = aws_vpc.eks_cluster.id
  cidr_block        = "172.16.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "eks_nodes2"
  }
}

resource "aws_subnet" "eks_public" {
  vpc_id            = aws_vpc.eks_cluster.id
  cidr_block        = "172.16.99.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "eks_public"
  }
}

resource "aws_eip" "elastic_ip" {
  domain = "vpc"
  tags = {
    Name = "EKS NATGW EIP"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.eks_cluster.id

  tags = {
    Name = "EKS IGW"
  }
}

resource "aws_nat_gateway" "nat_gateway" {
  subnet_id     = aws_subnet.eks_public.id
  allocation_id = aws_eip.elastic_ip.id

  tags = {
    Name = "EKS Private NATGW"
  }
  depends_on = [aws_internet_gateway.gw]
}

resource "aws_route_table_association" "nat_gateway" {
  subnet_id      = aws_subnet.eks_nodes.id
  route_table_id = aws_route_table.vpc_route_table.id
}

resource "aws_vpn_gateway" "eks_gw" {
  vpc_id = aws_vpc.eks_cluster.id

  tags = {
    Name = "eks-gw"
  }
}

resource "aws_customer_gateway" "remote_site" {
  bgp_asn    = 65000
  ip_address = google_compute_address.external_ip_vpn.address
  type       = "ipsec.1"

  tags = {
    Name = "gcp-remote"
  }
}


resource "aws_vpn_connection" "vpn_connection" {
  vpn_gateway_id       = aws_vpn_gateway.eks_gw.id
  customer_gateway_id  = aws_customer_gateway.remote_site.id
  type                 = "ipsec.1"
  tunnel1_ike_versions = ["ikev1"]

  static_routes_only = true

  tags = {
    Name = "Tunnel-to-GCP"
  }
}

resource "aws_vpn_connection_route" "route_to_gcp" {
  vpn_connection_id      = aws_vpn_connection.vpn_connection.id
  destination_cidr_block = "192.168.1.0/24"
}


resource "aws_route_table" "vpc_route_table" {
  vpc_id = aws_vpc.eks_cluster.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }
  tags = {
    Name = "eks_cluster"
  }
}

resource "aws_route_table" "vpc_route_table_public" {
  vpc_id = aws_vpc.eks_cluster.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "eks_cluster_public"
  }
}


resource "aws_route_table_association" "igw" {
  subnet_id      = aws_subnet.eks_public.id
  route_table_id = aws_route_table.vpc_route_table_public.id
}

resource "aws_vpn_gateway_route_propagation" "route_propagation" {
  vpn_gateway_id = aws_vpn_gateway.eks_gw.id
  route_table_id = aws_route_table.vpc_route_table.id
}