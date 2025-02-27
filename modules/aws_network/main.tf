locals {
  private_to_public_mapping = flatten([
    for priv_subnet in var.private_subnets : [
      for pub_subnet in var.public_subnets : {
        priv_subnet_cidr = priv_subnet.cidr
        pub_subnet_cidr  = pub_subnet.cidr
        az               = pub_subnet.az

      } if pub_subnet.az == priv_subnet.az && priv_subnet.eks_enabled && var.internet_access
    ]
  ])
  subnets_by_az = {
    for az in distinct([for item in local.private_to_public_mapping : item.az]) : az => [
      for item in local.private_to_public_mapping : {
        priv_subnet_cidr = item.priv_subnet_cidr
        pub_subnet_cidr  = item.pub_subnet_cidr
      }
      if item.az == az
    ]
  }
}



resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  tags = {
    Name = var.name
  }
}

resource "aws_subnet" "private_subnet" {
  for_each          = { for subnet in var.private_subnets : subnet.cidr => subnet }
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az
  tags = {
    Name                              = "${var.name}-private-${each.value.cidr}"
    "kubernetes.io/role/internal-elb" = each.value.eks_enabled ? 1 : 0 # Required by the AWS Load Balancer Controller
  }
}

resource "aws_subnet" "public_subnet" {
  for_each          = { for subnet in var.public_subnets : subnet.cidr => subnet }
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = {
    Name                     = "${var.name}-public-${each.value.cidr}"
    "kubernetes.io/role/elb" = each.value.eks_enabled ? 1 : 0 # Required by the AWS Load Balancer Controller
  }
}

# Create if there egress Internet access is enabled
resource "aws_eip" "elastic_ip" {
  for_each = local.subnets_by_az
  domain   = "vpc"
  tags = {
    Name = "NAT Gateway EIP AZ ${each.key}"
  }
}

resource "aws_internet_gateway" "internet_gw" {
  count  = var.internet_access ? 1 : 0
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "Internet GW (${var.name})"
  }
}

# TODO: No validation that a given AZ has a private and public subnets
resource "aws_nat_gateway" "nat_gateway" {
  for_each      = local.subnets_by_az
  subnet_id     = aws_subnet.public_subnet[each.value[0].pub_subnet_cidr].id # NAT GW created in the first public subnet
  allocation_id = aws_eip.elastic_ip[each.key].id

  tags = {
    Name = "NAT GW AZ ${each.key} (${var.name})"
  }
  depends_on = [aws_internet_gateway.internet_gw[0]]
}

resource "aws_route_table" "route_table_private_subnet" {
  for_each = local.subnets_by_az
  vpc_id   = aws_vpc.vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway[each.key].id
  }
  tags = {
    Name = "Private Route Table Subnet ${each.value[0].priv_subnet_cidr} (${var.name})"
  }
}

resource "aws_route_table_association" "route_table_association_private" {
  for_each       = local.subnets_by_az
  subnet_id      = aws_subnet.private_subnet[each.value[0].priv_subnet_cidr].id
  route_table_id = aws_route_table.route_table_private_subnet[each.key].id
}

resource "aws_route_table" "route_table_public_subnet" {
  for_each = { for subnet in var.public_subnets : subnet.cidr => subnet if var.internet_access }
  vpc_id   = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gw[0].id
  }
  tags = {
    Name = "Public Route Table Subnet ${each.value.cidr} (${var.name})"
  }
}

resource "aws_route_table_association" "route_table_association_public" {
  for_each       = { for subnet in var.public_subnets : subnet.cidr => subnet if var.internet_access }
  subnet_id      = aws_subnet.public_subnet[each.value.cidr].id
  route_table_id = aws_route_table.route_table_public_subnet[each.value.cidr].id
}
