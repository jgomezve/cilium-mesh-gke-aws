provider "aws" {
  region = var.aws_region
}

provider "google" {
  project = "cilium-mesh-489420"
  region  = var.gcp_region
  zone    = var.gcp_zone
}

module "eks_vpc" {
  count           = var.aws_network ? 1 : 0
  source          = "./modules/aws_network"
  name            = "eks-cilium"
  vpc_cidr        = var.aws_vpc_cidr
  public_subnets  = var.aws_public_subnets
  private_subnets = var.aws_private_subnets
}

module "gke_vpc" {
  count  = var.gcp_network ? 1 : 0
  source = "./modules/gcp_network"
  name   = "gke-cilium"
  region = var.gcp_region
  private_subnets = [
    {
      cidr   = var.gcp_vpc_cidr
      region = var.gcp_region
    }
  ]
}

module "vpn_aws_gcp" {
  count                = var.aws_network && var.gcp_network && var.aws_gcp_vpn ? 1 : 0
  source               = "./modules/aws_gcp_vpn"
  aws_vpc_name         = module.eks_vpc[0].vpc_name
  gcp_vpc_name         = module.gke_vpc[0].vpc_name
  name                 = "cilium"
  cidr_gcp             = var.gcp_vpc_cidr
  cidr_aws             = var.aws_vpc_cidr
  aws_route_tables_ids = module.eks_vpc[0].private_route_tables_id
  region               = var.gcp_region
  depends_on           = [module.eks_vpc, module.gke_vpc]
}

module "aws_ec2_tshoot" {
  count        = var.tshoot_vms && var.aws_network ? 1 : 0
  source       = "./modules/aws_vm"
  name         = "test-vm"
  vpc_id       = module.eks_vpc[0].vpc_id
  subnet_id    = module.eks_vpc[0].private_subnets_id[0]
  ssh_key_name = var.ec2_ssh_key_name
}

module "gcp_vm_tshoot" {
  count     = var.tshoot_vms && var.gcp_network ? 1 : 0
  source    = "./modules/gcp_vm"
  name      = "test-vm"
  vpc_name  = module.gke_vpc[0].vpc_name
  vpc_id    = module.gke_vpc[0].vpc_id
  subnet_id = module.gke_vpc[0].private_subnets_id[0]
  zone      = var.gcp_zone
}

module "eks_cluster" {
  count  = var.eks_cluster && var.aws_network ? 1 : 0
  source = "./modules/eks_cluster"
  name   = "eks-cilium"
  # ssh_keys_name               = var.ec2_ssh_key_name
  eks_vpc_id                  = module.eks_vpc[0].vpc_id
  eks_ec2_cluster_subnets_ids = module.eks_vpc[0].private_subnets_id_eks_enabled
  eks_cluster_subnets_ids     = module.eks_vpc[0].private_subnets_id
  roles_with_access           = var.eks_roles_with_access # IAM roles/users granted kubectl access
  eks_addons                  = ["coredns"]
}

module "gke_cluster" {
  count         = var.gke_cluster && var.gcp_network ? 1 : 0
  source        = "./modules/gke_cluster"
  name          = "gke-cilium"
  pod_cidr      = var.gke_pod_cidr
  gke_vpc_name  = module.gke_vpc[0].vpc_name
  gke_vpc_id    = module.gke_vpc[0].vpc_id
  gke_subnet_id = module.gke_vpc[0].private_subnets_id[0] # GKE uses the first defined subnet
  location      = var.gcp_zone                            # Zonal cluster
}
