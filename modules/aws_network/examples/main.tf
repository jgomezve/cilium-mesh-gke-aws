module "aws_vpc" {
  source   = ".."
  name     = "my-vpc"
  vpc_cidr = "192.168.0.0/16"
  public_subnets = [
    {
      cidr = "192.168.91.0/24"
      az   = "us-east-1a"
    },
    {
      cidr = "192.168.92.0/24"
      az   = "us-east-1b"
    }
  ]
  private_subnets = [
    {
      cidr = "192.168.1.0/24"
      az   = "us-east-1a"
    },
    {
      cidr   = "192.168.2.0/24"
      az     = "us-east-1b"
      nat_gw = false
    }
  ]
}