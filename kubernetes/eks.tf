provider "aws" {
  region = "us-east-1"
}


data "aws_iam_role" "eks_role" {
  name = "eks-role"
}

data "aws_iam_role" "ec2_eks_role" {
  name = "ec2-eks-role"
}

data "aws_subnet" "subnet_az1" {
  filter {
    name   = "tag:Name"
    values = ["eks_nodes"]
  }
}

data "aws_subnet" "subnet_az2" {
  filter {
    name   = "tag:Name"
    values = ["eks_nodes2"]
  }
}

data "aws_security_group" "selected" {
  name = "example-security-group"
}


resource "aws_eks_cluster" "example" {
  name = "eks-cilium"

  access_config {
    authentication_mode = "API"
  }

  role_arn = data.aws_iam_role.eks_role.arn
  version  = "1.31"

  vpc_config {
    endpoint_private_access = true
    endpoint_public_access  = true
    subnet_ids = [
      data.aws_subnet.subnet_az1.id,
      data.aws_subnet.subnet_az2.id,
    ]
  }
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.example.name
  addon_name   = "vpc-cni"
}

resource "aws_eks_addon" "core_dns" {
  cluster_name = aws_eks_cluster.example.name
  addon_name   = "coredns"
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.example.name
  addon_name   = "kube-proxy"
}

resource "aws_eks_node_group" "my_node_group" {
  cluster_name    = aws_eks_cluster.example.id
  node_group_name = "eks-cilium-nodes"
  node_role_arn   = data.aws_iam_role.ec2_eks_role.arn
  subnet_ids =  [
      data.aws_subnet.subnet_az1.id,
    ]

  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }

  remote_access {
    ec2_ssh_key = "my-demo-key"
    #source_security_group_ids = [data.aws_security_group.selected.id] # CHECK NOT WORKING
  }

   instance_types = ["t2.medium"]
   ami_type = "AL2_x86_64"
}