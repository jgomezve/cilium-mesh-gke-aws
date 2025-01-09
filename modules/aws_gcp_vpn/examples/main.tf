module "aws_gcp_vpn" {
  source               = "../"
  aws_vpc_name         = "aws-vpc"
  gcp_vpc_name         = "gcp-vpc"
  name                 = "cilium"
  cidr_gcp             = "172.25.1.0/24"
  cidr_aws             = "192.168.0.0/16"
  aws_route_tables_ids = [aws_route_table.default.id]
  region               = "us-central1"
}