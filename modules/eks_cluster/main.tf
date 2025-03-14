resource "aws_iam_role" "eks_cluster_role" {
  name = "EKS-${var.name}-ClusterRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "eks.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy_attachment" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role" "eks_worker_role" {
  name = "EKS-${var.name}-WorkerNodeRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_policy_attachment_cr_ro" {
  role       = aws_iam_role.eks_worker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "ec2_policy_attachment_eks_cni" {
  role       = aws_iam_role.eks_worker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "ec2_policy_attachment_eks_worker" {
  role       = aws_iam_role.eks_worker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_eks_cluster" "cluster" {
  name = var.name

  access_config {
    authentication_mode = var.authentication_mode
  }

  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = var.eks_version

  vpc_config {
    endpoint_private_access = var.private_endpoint
    endpoint_public_access  = var.public_endpoint
    subnet_ids              = var.eks_cluster_subnets_ids
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy_attachment,
  ]
}

resource "aws_eks_access_entry" "access_role" {
  for_each      = toset(var.roles_with_access)
  cluster_name  = aws_eks_cluster.cluster.name
  principal_arn = each.value
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "policy_association" {
  for_each      = toset(var.roles_with_access)
  cluster_name  = aws_eks_cluster.cluster.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = each.value

  access_scope {
    type = "cluster"
  }
}

resource "aws_eks_addon" "eks_addon" {
  for_each     = toset(var.eks_addons)
  cluster_name = aws_eks_cluster.cluster.name
  addon_name   = each.value
}

resource "aws_eks_node_group" "node_group" {
  cluster_name    = aws_eks_cluster.cluster.id
  node_group_name = "${var.name}-nodes"
  node_role_arn   = aws_iam_role.eks_worker_role.arn
  subnet_ids      = var.eks_ec2_cluster_subnets_ids != [] ? var.eks_ec2_cluster_subnets_ids : var.eks_cluster_subnets_ids

  scaling_config {
    desired_size = var.desired_nodes
    max_size     = var.maximum_nodes
    min_size     = var.minimum_nodes
  }

  launch_template {
    id      = aws_launch_template.aws_launch_template.id
    version = aws_launch_template.aws_launch_template.latest_version
  }

  # taint {
  #   key    = "node.cilium.io/agent-not-ready"
  #   value  = "true"
  #   effect = "NO_EXECUTE"
  # }

  # remote_access {
  #   ec2_ssh_key = var.ssh_keys_name
  # }

  # instance_types = var.instance_types
  # ami_type       = var.ami_type
}


resource "aws_launch_template" "aws_launch_template" {
  name                   = "eks-node-launch-template"
  update_default_version = true
  instance_type          = "t3.medium"
  vpc_security_group_ids = [aws_security_group.worker_security_group.id, aws_eks_cluster.cluster.vpc_config[0].cluster_security_group_id]

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = 20
      volume_type = "gp2"
    }
  }

  key_name = var.ssh_keys_name

}

resource "aws_security_group" "worker_security_group" {
  name        = "EKS-${var.name}-worker_security_group"
  description = "Allow SSH, HTTP, and ICMP inbound traffic"
  vpc_id      = var.eks_vpc_id

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # tags = {
  #   "kubernetes.io/cluster/${var.name}" = "owned" # Required by the AWS Load Balancer Controller
  #   "aws:eks:cluster-name"              = var.name
  #   "Name"                              = "eks-cluster-sq-worker_security_group"
  # }
}