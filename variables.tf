# ─── Global ─────────────────────────────────────────────────────────────────────

variable "gcp_network" {
  default = false
}

variable "aws_network" {
  default = false
}

variable "aws_gcp_vpn" {
  default = false
}

variable "eks_cluster" {
  default = false
}

variable "gke_cluster" {
  default = false
}

variable "tshoot_vms" {
  default = false
}

# ─── AWS ─────────────────────────────────────────────────────────────────────

variable "aws_region" {
  description = "AWS region where all resources will be deployed."
  type        = string
  default     = "us-east-1"
}

variable "aws_vpc_cidr" {
  description = "CIDR block for the AWS VPC."
  type        = string
  default     = "192.168.0.0/16"
}

variable "aws_public_subnets" {
  description = "List of public subnet definitions (cidr, az, optional eks_enabled)."
  type = list(object({
    cidr        = string
    az          = string
    eks_enabled = optional(bool, true)
  }))
  default = [
    { cidr = "192.168.91.0/24", az = "us-east-1a" },
    { cidr = "192.168.92.0/24", az = "us-east-1b", eks_enabled = false }
  ]
}

variable "aws_private_subnets" {
  description = "List of private subnet definitions (cidr, az, optional eks_enabled)."
  type = list(object({
    cidr        = string
    az          = string
    eks_enabled = optional(bool, true)
  }))
  default = [
    { cidr = "192.168.1.0/24", az = "us-east-1a" },
    { cidr = "192.168.2.0/24", az = "us-east-1b", eks_enabled = false }
  ]
}

variable "ec2_ssh_key_name" {
  description = "Name of the existing AWS EC2 Key Pair used for the troubleshooting VM."
  type        = string
  default     = "my-demo-key"
}

variable "eks_roles_with_access" {
  description = "List of IAM role/user ARNs that will be granted access to the EKS cluster. Supply via TF_VAR_eks_roles_with_access env var — do not commit to tfvars."
  type        = list(string)
}

# ─── GCP ─────────────────────────────────────────────────────────────────────

variable "gcp_region" {
  description = "GCP region where all resources will be deployed."
  type        = string
  default     = "us-central1"
}

variable "gcp_zone" {
  description = "GCP zone used for zonal resources (GKE cluster, troubleshooting VM)."
  type        = string
  default     = "us-central1-a"
}

variable "gcp_vpc_cidr" {
  description = "CIDR block for the GCP VPC private subnet."
  type        = string
  default     = "172.25.1.0/24"
}

variable "gke_pod_cidr" {
  description = "CIDR block assigned to GKE pods."
  type        = string
  default     = "10.111.0.0/16"
}
