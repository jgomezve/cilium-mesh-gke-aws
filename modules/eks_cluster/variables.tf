variable "name" {
  description = "Cluster's Name"
  type        = string
}

variable "authentication_mode" {
  description = "EKS Authentication mode"
  type        = string
  default     = "API"
}

variable "eks_version" {
  description = "EKS Version"
  type        = string
  default     = "1.31"
}

variable "private_endpoint" {
  description = "EKS API private flag"
  type        = bool
  default     = true
}

variable "public_endpoint" {
  description = "EKS API public flag"
  type        = bool
  default     = true

}

variable "eks_vpc_id" {
  description = "ID of VPC for the EKS cluster"
  type        = string
}


variable "eks_cluster_subnets_ids" {
  description = "List of subnet ids for the EKS cluster. Subnets must be in different AZ"
  type        = list(string)
}

variable "eks_addons" {
  description = "List of Addons to install on EKS"
  type        = list(string)
  default     = ["vpc-cni", "kube-proxy", "coredns"]
}

variable "minimum_nodes" {
  description = "Minimum number of nodes in cluster"
  default     = 1
  type        = number
}

variable "maximum_nodes" {
  description = "Maximum number of nodes in cluster"
  type        = number
  default     = 1
}

variable "desired_nodes" {
  description = "Desired number of nodes in cluster"
  type        = number
  default     = 1
}

variable "ssh_keys_name" {
  description = "Name of SSH keas for the worker nodes"
  type        = string
}

variable "instance_types" {
  description = "List of desired EC2 instance types for the worker nodes"
  type        = list(string)
  default     = ["t2.medium"]
}

variable "ami_type" {
  description = "AMI Type for the worker nodes"
  type        = string
  default     = "AL2_x86_64"
}


variable "roles_with_access" {
  description = "List of IAM ARN that can access the cluster"
  type        = list(string)
}

variable "load_balancer_ctrl_requirements" {
  description = "Flag to create infra required by the AWS Load Balancer Controller"
  type        = bool
  default     = true
}