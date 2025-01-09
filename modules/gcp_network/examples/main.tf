module "gcp_vpc" {
  source = ".."
  name   = "gke-vpc"
  region = "us-central1"
  private_subnets = [
    {
      cidr   = "172.16.1.0/24"
      region = "us-central1"
    }
  ]

}