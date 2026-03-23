gcp_network = true
aws_network = true
aws_gcp_vpn = true

eks_cluster = true
gke_cluster = true
tshoot_vms  = false

# ─── AWS ─────────────────────────────────────────────────────────────────────
aws_region   = "us-east-1"
aws_vpc_cidr = "192.168.0.0/16"

aws_public_subnets = [
  {
    cidr = "192.168.91.0/24",
    az   = "us-east-1a"
  },
  {
    cidr        = "192.168.92.0/24",
    az          = "us-east-1b",
    eks_enabled = false
  }
]

aws_private_subnets = [
  {
    cidr = "192.168.1.0/24",
  az = "us-east-1a" },
  {
    cidr = "192.168.2.0/24",
    az   = "us-east-1b",
  eks_enabled = false }
]

ec2_ssh_key_name = "my-demo-key"

# eks_roles_with_access is intentionally omitted — set via environment variable:
#   export TF_VAR_eks_roles_with_access='["arn:aws:iam::<ACCOUNT_ID>:user/<USERNAME>"]'

# ─── GCP ─────────────────────────────────────────────────────────────────────
gcp_region   = "us-central1"
gcp_zone     = "us-central1-a"
gcp_vpc_cidr = "172.25.1.0/24"
gke_pod_cidr = "10.111.0.0/16"