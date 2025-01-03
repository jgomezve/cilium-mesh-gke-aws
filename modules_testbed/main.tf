provider "aws" {
  region = "us-east-1"
}

provider "google" {
  project = "gke-cilium-443902"
  region  = "us-central1"
  zone    = "us-central1-a"
}

module "eks_vpc" {
  source   = "../modules/aws_network"
  name     = "eks-cilium"
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
      cidr = "192.168.2.0/24"
      az   = "us-east-1b"
      #nat_gw = false
    }
  ]
}

module "gke_vpc" {
  source = "../modules/gcp_network"
  name   = "gke-cilium"
  region = "us-central1"
  private_subnets = [
    {
      cidr   = "172.25.1.0/24"
      region = "us-central1"
    }
  ]

}

module "eks_cluster" {
  source                  = "../modules/eks_cluster"
  name                    = "eks-cilium"
  ssh_keys_name           = "my-demo-key"
  eks_vpc_id              = module.eks_vpc.vpc_id
  eks_cluster_subnets_ids = module.eks_vpc.private_subnets_id
  roles_with_access       = ["arn:aws:iam::640168443445:user/aws-cli"] # Role use by aks-cli. So I can access the cluster using kubectl
  # eks_addons              = ["kube-proxy", "vpc-cni"]
}


module "gke_cluster" {
  source        = "../modules/gke_cluster"
  name          = "gke-cilium"
  pod_cidr      = "10.111.0.0/16"
  gke_vpc_id    = module.gke_vpc.vpc_id
  gke_subnet_id = module.gke_vpc.private_subnets_id[0] # GKE uses the first defined subnet
  location      = "us-central1-a"                      # Zonal cluster
}