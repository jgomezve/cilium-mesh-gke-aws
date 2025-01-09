provider "aws" {
  region = "us-east-1"
}

provider "google" {
  project = "gke-cilium-443902"
  region  = "us-central1"
  zone    = "us-central1-a"
}

module "eks_vpc" {
  count    = var.aws_network ? 1 : 0
  source   = "./modules/aws_network"
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
  count  = var.gcp_network ? 1 : 0
  source = "./modules/gcp_network"
  name   = "gke-cilium"
  region = "us-central1"
  private_subnets = [
    {
      cidr   = "172.25.1.0/24"
      region = "us-central1"
    }
  ]

}

module "vpn_aws_gcp" {
  count                = var.aws_network && var.gcp_network && var.aws_gcp_vpn ? 1 : 0
  source               = "./modules/aws_gcp_vpn"
  aws_vpc_name         = module.eks_vpc[0].vpc_name
  gcp_vpc_name         = module.gke_vpc[0].vpc_name
  name                 = "cilium"
  cidr_gcp             = "172.25.1.0/24"
  cidr_aws             = "192.168.0.0/16"
  aws_route_tables_ids = module.eks_vpc[0].private_route_tables_id
  region               = "us-central1"
  depends_on           = [module.eks_vpc, module.gke_vpc]
}

module "aws_ec2_tshoot" {
  count        = var.tshoot_vms && var.aws_network ? 1 : 0
  source       = "./modules/aws_vm"
  name         = "test-vm"
  vpc_id       = module.eks_vpc[0].vpc_id
  subnet_id    = module.eks_vpc[0].private_subnets_id[0]
  ssh_key_name = "my-demo-key"

}

module "gcp_vm_tshoot" {
  count     = var.tshoot_vms && var.gcp_network ? 1 : 0
  source    = "./modules/gcp_vm"
  name      = "test-vm"
  vpc_name  = module.gke_vpc[0].vpc_name
  vpc_id    = module.gke_vpc[0].vpc_id
  subnet_id = module.gke_vpc[0].private_subnets_id[0]
  zone      = "us-central1-a"
}

module "eks_cluster" {
  count                   = var.eks_cluster && var.aws_network ? 1 : 0
  source                  = "./modules/eks_cluster"
  name                    = "eks-cilium"
  ssh_keys_name           = "my-demo-key"
  eks_vpc_id              = module.eks_vpc[0].vpc_id
  eks_cluster_subnets_ids = module.eks_vpc[0].private_subnets_id
  roles_with_access       = ["arn:aws:iam::640168443445:user/aws-cli"] # Role use by aks-cli. So I can access the cluster using kubectl
  # eks_addons              = ["kube-proxy", "vpc-cni"]
}

module "gke_cluster" {
  count         = var.gke_cluster && var.aws_network ? 1 : 0
  source        = "./modules/gke_cluster"
  name          = "gke-cilium"
  pod_cidr      = "10.111.0.0/16"
  gke_vpc_name  = module.gke_vpc[0].vpc_name
  gke_vpc_id    = module.gke_vpc[0].vpc_id
  gke_subnet_id = module.gke_vpc[0].private_subnets_id[0] # GKE uses the first defined subnet
  location      = "us-central1-a"                         # Zonal clusterå
}