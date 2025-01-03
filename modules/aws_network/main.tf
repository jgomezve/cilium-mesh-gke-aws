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
    "kubernetes.io/role/internal-elb" = 1 # Required by the AWS Load Balancer Controller
  }
}

resource "aws_subnet" "public_subnet" {
  for_each          = { for subnet in var.public_subnets : subnet.cidr => subnet }
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = {
    Name = "${var.name}-public-${each.value.cidr}"
  }
}

# Create if there egress Internet access is enabled
resource "aws_eip" "elastic_ip" {
  for_each = { for subnet in var.private_subnets : subnet.az => subnet if var.internet_access && subnet.nat_gw }
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
  for_each      = { for subnet in var.public_subnets : subnet.az => subnet if var.internet_access }
  subnet_id     = aws_subnet.public_subnet[each.value.cidr].id
  allocation_id = aws_eip.elastic_ip[each.value.az].id

  tags = {
    Name = "NAT GW Subnet ${each.value.cidr} (${var.name})"
  }
  depends_on = [aws_internet_gateway.internet_gw[0]]
}

resource "aws_route_table" "route_table_private_subnet" {
  for_each = { for subnet in var.private_subnets : subnet.cidr => subnet if var.internet_access && subnet.nat_gw }
  vpc_id   = aws_vpc.vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway[each.value.az].id
  }
  tags = {
    Name = "Private Route Table Subnet ${each.value.cidr} (${var.name})"
  }
}

resource "aws_route_table_association" "route_table_association_private" {
  for_each       = { for subnet in var.private_subnets : subnet.cidr => subnet if var.internet_access && subnet.nat_gw }
  subnet_id      = aws_subnet.private_subnet[each.value.cidr].id
  route_table_id = aws_route_table.route_table_private_subnet[each.value.cidr].id
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
