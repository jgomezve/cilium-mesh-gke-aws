module "eks_cluster" {
  source                  = ".."
  name                    = "my-cluster"
  ssh_keys_name           = "my-ssh-key"
  eks_vpc_id              = aws_vpc.vpc.id
  eks_cluster_subnets_ids = [aws_subnet.private_subnets.id]
  roles_with_access       = ["arn:aws:iam::00000:user/aws-cli"]
  eks_addons              = ["kube-proxy", "vpc-cni"]
}