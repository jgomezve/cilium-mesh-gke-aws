# Cilium Cluster Mesh Sandbox

This sandbox deploys a [Cilium Cluster Mesh](https://docs.cilium.io/en/stable/network/clustermesh/clustermesh/) across an AWS EKS cluster and a GCP GKE cluster, connected via a site-to-site VPN. The infrastructure is fully managed with Terraform.

---

## Table of Contents

1. [Pre-requisites](#1-pre-requisites)
2. [Project Structure](#2-project-structure)
3. [Considerations for AWS and GCP](#3-considerations-for-aws-and-gcp)
4. [Setting Values in Terraform](#4-setting-values-in-terraform)
5. [Cloud Networking](#5-cloud-networking)
6. [Blog Post](#6-blog-post)
7. [Teardown](#7-teardown)
8. [Working with kubectl](#8-working-with-kubectl)

---

## 1. Pre-requisites

Install the following tools before deploying:

| Tool | Purpose | Install |
|------|---------|---------|
| `aws` CLI | Interact with AWS resources | [docs.aws.amazon.com](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) |
| `gcloud` CLI | Interact with GCP resources | [cloud.google.com/sdk](https://cloud.google.com/sdk/docs/install) |
| `gke-gcloud-auth-plugin` | Authenticate kubectl against GKE | [cloud.google.com/blog](https://cloud.google.com/blog/products/containers-kubernetes/kubectl-auth-changes-in-gke) |
| `kubectl` | Manage Kubernetes clusters | [kubernetes.io](https://kubernetes.io/docs/tasks/tools/) |
| `helm` | Deploy Kubernetes applications | [helm.sh](https://helm.sh/docs/intro/install/) |
| `cilium` CLI | Install and manage Cilium | [docs.cilium.io](https://docs.cilium.io/en/stable/gettingstarted/k8s-install-default/#install-the-cilium-cli) |
| `terraform` | Provision cloud infrastructure | [developer.hashicorp.com](https://developer.hashicorp.com/terraform/install) |

---

## 2. Project Structure

```
.
├── main.tf                    # Root module – wires all child modules together
├── variables.tf               # Input variable declarations
├── variables.auto.tfvars      # Variable values (customise here)
├── manifests/
│   └──   bookstore/             # Demo bookstore application manifests
└── modules/
    ├── aws_network/           # AWS VPC, subnets, route tables
    ├── aws_vm/                # EC2 troubleshooting VM
    ├── aws_gcp_vpn/           # Site-to-site VPN between AWS and GCP
    ├── eks_cluster/           # EKS cluster with managed node group
    ├── gcp_network/           # GCP VPC and subnets
    ├── gcp_vm/                # GCE troubleshooting VM
    └── gke_cluster/           # GKE cluster (zonal, Dataplane V2 / Cilium)
```

---

## 3. Considerations for AWS and GCP

### Network design

The two clouds are connected over a **site-to-site IPsec VPN** (AWS Virtual Private Gateway ↔ GCP Classic VPN). Traffic between clusters flows through the VPN tunnel, so pod-to-pod cross-cloud latency depends on the chosen regions.

```
┌────────────────────────────────────────────┐  IPsec VPN  ┌────────────────────────────────────────────┐
│                   AWS                      │ ◄─────────► │                   GCP                      │
│                                            │             │                                            │
│  VPC: 192.168.0.0/16                       │             │  VPC (node subnet): 172.25.1.0/24          │
│  ┌──────────────────────────────────────┐  │             │  ┌──────────────────────────────────────┐  │
│  │  EKS cluster                         │  │             │  │  GKE cluster                         │  │
│  │  Pods: 10.222.0.0/16 (set by Cilium) │  │  Cilium     │  │  Pods: 10.111.0.0/16 (alias range)   │  │
│  │  ← overlay CNI, NOT in VPN route     │  │ ~~tunnel~~► │  │  ← secondary CIDR, NOT in VPN route  │  │
│  └──────────────────────────────────────┘  │             │  └──────────────────────────────────────┘  │
└────────────────────────────────────────────┘             └────────────────────────────────────────────┘
```

### AWS — key decisions

- **VPC CIDR** (`192.168.0.0/16`) must not overlap with the GCP node subnet or GKE pod CIDR.
- **Public subnets** are tagged for the AWS Load Balancer Controller so that internet-facing `LoadBalancer` services are placed there automatically.
- **Private subnets** host EKS worker nodes. Only subnets with `eks_enabled = true` are registered as cluster subnets in the EKS API.
- **Two Availability Zones** are used to satisfy EKS's minimum AZ requirement for a highly-available control plane.
- The **AWS Virtual Private Gateway** attaches to the VPC and BGP is not used — static routes propagate only the GCP **node** CIDR (`172.25.1.0/24`) into the private route tables.
- An optional **EC2 troubleshooting VM** is placed in a private subnet for reachability testing across the VPN.


### GCP — key decisions

- **GKE** is deployed as a **zonal cluster** (single zone) to minimise cost in a sandbox environment.
- **Dataplane V2** (eBPF / Cilium) is enabled natively on GKE, which is a requirement for Cilium Cluster Mesh.
- The **node subnet** (`172.25.1.0/24`) must not overlap with any AWS CIDR. This is the only GCP range added to the VPN static route on the AWS side.
- The **GKE pod CIDR** (`10.111.0.0/16`) is a secondary alias range — it is **not** routed over the VPN. Cross-cloud pod traffic relies entirely on Cilium Cluster Mesh tunnelling.
- The **Classic VPN gateway** creates two redundant tunnels toward AWS for resilience.
- An optional **GCE troubleshooting VM** mirrors the EC2 VM on the AWS side.

---

## 4. Setting Values in Terraform

All tuneable parameters are exposed as Terraform variables. Edit **`variables.auto.tfvars`** to customise a deployment — no changes to `main.tf` are needed.

### Feature flags

Control which components are deployed:

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `aws_network` | `bool` | `false` | Deploy the AWS VPC and subnets |
| `gcp_network` | `bool` | `false` | Deploy the GCP VPC and subnet |
| `aws_gcp_vpn` | `bool` | `false` | Deploy the site-to-site VPN (requires both networks) |
| `eks_cluster` | `bool` | `false` | Deploy the EKS cluster |
| `gke_cluster` | `bool` | `false` | Deploy the GKE cluster |
| `tshoot_vms` | `bool` | `false` | Deploy EC2 and GCE troubleshooting VMs |

### AWS variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `aws_region` | `string` | `us-east-1` | AWS region for all resources |
| `aws_vpc_cidr` | `string` | `192.168.0.0/16` | CIDR block for the AWS VPC |
| `aws_public_subnets` | `list(object)` | see below | Public subnets — each entry has `cidr`, `az`, and optional `eks_enabled` |
| `aws_private_subnets` | `list(object)` | see below | Private subnets — each entry has `cidr`, `az`, and optional `eks_enabled` |
| `ec2_ssh_key_name` | `string` | `my-demo-key` | Name of an existing EC2 Key Pair for the troubleshooting VM |
| `eks_roles_with_access` | `list(string)` | — | IAM role/user ARNs granted `kubectl` access to the EKS cluster. **Must be set via `TF_VAR_eks_roles_with_access` env var** — never commit to tfvars |

### GCP variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `gcp_region` | `string` | `us-central1` | GCP region for all resources |
| `gcp_zone` | `string` | `us-central1-a` | GCP zone for zonal resources (GKE cluster, troubleshooting VM) |
| `gcp_vpc_cidr` | `string` | `172.25.1.0/24` | CIDR block for the GCP VPC private subnet |
| `gke_pod_cidr` | `string` | `10.111.0.0/16` | Secondary CIDR assigned to GKE pods |

### Example `variables.auto.tfvars`

```hcl
# Feature flags
aws_network = true
gcp_network = true
aws_gcp_vpn = true
eks_cluster = true
gke_cluster = true
tshoot_vms  = false

# AWS
aws_region   = "us-east-1"
aws_vpc_cidr = "192.168.0.0/16"

aws_public_subnets = [
  { cidr = "192.168.91.0/24", az = "us-east-1a" },
  { cidr = "192.168.92.0/24", az = "us-east-1b", eks_enabled = false }
]

aws_private_subnets = [
  { cidr = "192.168.1.0/24", az = "us-east-1a" },
  { cidr = "192.168.2.0/24", az = "us-east-1b", eks_enabled = false }
]

ec2_ssh_key_name = "my-demo-key"

# eks_roles_with_access is intentionally omitted — set via environment variable (see below)

# GCP
gcp_region   = "us-central1"
gcp_zone     = "us-central1-a"
gcp_vpc_cidr = "172.25.1.0/24"
gke_pod_cidr = "10.111.0.0/16"
```

> **CIDR overlap rules:**
> `aws_vpc_cidr`, `gcp_vpc_cidr`, and `gke_pod_cidr` must be three non-overlapping ranges.

### Sensitive variables

`eks_roles_with_access` contains IAM ARNs that identify who can access your cluster. It must **not** be committed to the repository. Supply it at runtime via a `TF_VAR_*` environment variable — Terraform automatically maps any `TF_VAR_<name>` env var to the corresponding input variable.

For a `list(string)` variable the value must be a JSON array:

```bash
export TF_VAR_eks_roles_with_access='["arn:aws:iam::<ACCOUNT_ID>:role/<ROLE_NAME>"]'
```

Multiple principals:

```bash
export TF_VAR_eks_roles_with_access='["arn:aws:iam::<ACCOUNT_ID>:user/<USERNAME>","arn:aws:iam::<ACCOUNT_ID>:role/<ROLE_NAME>"]'
```

> Store this `export` in your shell profile (e.g. `~/.zshrc`) or a local `.env` file that is listed in `.gitignore`. Never put it in `variables.auto.tfvars`.

### Deploying

```bash
# 1. Set the sensitive variable
export TF_VAR_eks_roles_with_access='["arn:aws:iam::<ACCOUNT_ID>:user/<USERNAME>"]'

# 2. Deploy
terraform init
terraform plan
terraform apply
```

---

## 5. Cloud Networking

Use the commands below to verify that all networking layers (VPC, VPN, routing, compute) are correctly provisioned and reachable.

### AWS

**List VPC subnets**

```bash
aws ec2 describe-subnets \
    --filters "Name=tag:Name,Values=eks-cilium*" \
    --query 'Subnets[*].{
        Subnet: Tags[?Key==`Name`].Value | [0],
        CIDR: CidrBlock,
        VpcID: VpcId
    }' \
    --output table
```

```console
-----------------------------------------------------------------------------------
|                                 DescribeSubnets                                 |
+-----------------+-------------------------------------+-------------------------+
|      CIDR       |               Subnet                |          VpcID          |
+-----------------+-------------------------------------+-------------------------+
|  192.168.2.0/24 |  eks-cilium-private-192.168.2.0/24  |  vpc-02e4d622a5eb579a9  |
|  192.168.1.0/24 |  eks-cilium-private-192.168.1.0/24  |  vpc-02e4d622a5eb579a9  |
|  192.168.91.0/24|  eks-cilium-public-192.168.91.0/24  |  vpc-02e4d622a5eb579a9  |
|  192.168.92.0/24|  eks-cilium-public-192.168.92.0/24  |  vpc-02e4d622a5eb579a9  |
+-----------------+-------------------------------------+-------------------------+
```

**Check VPN connection status and static routes**

```bash
aws ec2 describe-vpn-connections \
    --query 'VpnConnections[*].{
        Name: Tags[?Key==`Name`].Value | [0],
        VPN_ID: VpnConnectionId,
        State: State,
        StaticRoutes: Routes[*].DestinationCidrBlock
    }' \
    --output table
```

```console
|+---------------------------------------------------------------------------+|
|                           DescribeVpnConnections                            |
+--------------------+------------+-----------------+-------------------------+
|        Name        |   State    | TransitGateway  |         VPN_ID          |
+--------------------+------------+-----------------+-------------------------+
|  Connection cilium |  available |  None           |  vpn-04855facfea5d724b  |
+--------------------+------------+-----------------+-------------------------+
||                               StaticRoutes                                ||
|+---------------------------------------------------------------------------+|
||  172.25.1.0/24                                                            ||
|+---------------------------------------------------------------------------+|
```

> The static route `172.25.1.0/24` must appear here for GCP-bound traffic to be routed through the VPN.

**List EKS worker nodes (EC2 instances)**

```bash
aws ec2 describe-instances \
    --query 'Reservations[*].Instances[*].{
        Name: Tags[?Key==`Name`].Value | [0],
        InstanceID: InstanceId,
        State: State.Name,
        SubnetID: SubnetId,
        VpcID: VpcId,
        PrivateIP: PrivateIpAddress
    }[]' \
    --output table
```

```console
------------------------------------------------------------------------------------------------------------------
|                                                DescribeInstances                                               |
+---------------------+-------+----------------+----------+----------------------------+-------------------------+
|     InstanceID      | Name  |   PrivateIP    |  State   |         SubnetID           |          VpcID          |
+---------------------+-------+----------------+----------+----------------------------+-------------------------+
|  i-0597fc696de50049f|  None |  192.168.1.118 |  running |  subnet-075582e905c95f473  |  vpc-0f4141cdd6ffe95ff  |
+---------------------+-------+----------------+----------+----------------------------+-------------------------+
```

> This lists the EC2 instances backing the EKS node group. Their private IPs are drawn from the VPC subnet (`192.168.1.0/24`) and are directly routable over the VPN toward GCP.

**Check AWS Load Balancer (Cluster Mesh / Gateway API)**

```bash
aws elbv2 describe-load-balancers \
    --query 'LoadBalancers[*].{Name:LoadBalancerName, State:State.Code, Scheme:Scheme, Subnets:AvailabilityZones[*].SubnetId}' \
    --output table
```

```console
------------------------------------------------------------------
|                      DescribeLoadBalancers                     |
+----------------------------------+-------------------+---------+
|               Name               |      Scheme       |  State  |
+----------------------------------+-------------------+---------+
|  k8s-default-ciliumga-302d831e91 |  internet-facing  |  active |
+----------------------------------+-------------------+---------+
||                            Subnets                           ||
|+--------------------------------------------------------------+|
||  subnet-0805fe839c8e0cb5d                                    ||
|+--------------------------------------------------------------+|
```

---

### GCP

**List GKE VPC subnets**

```bash
gcloud compute networks subnets list \
    --filter="name ~ ^gke-cilium" \
    --format="table(
        ipCidrRange:label=CIDR,
        name:label=SUBNET,
        network.basename():label=VPC_NAME,
        privateIpGoogleAccess:label=PRIVATE_G_ACCESS
    )"
```

```console
CIDR           SUBNET                        VPC_NAME    PRIVATE_G_ACCESS
172.25.1.0/24  gke-cilium--172--25--1--0-24  gke-cilium  True
```

**Check VPN tunnel status**

```bash
gcloud compute vpn-tunnels list \
    --format="table(
        name,
        region.basename(),
        vpnGateway.basename():label=GATEWAY,
        peerIp,
        status
    )"
```

```console
NAME     REGION       GATEWAY  PEER_ADDRESS   STATUS
tunnel1  us-central1           50.17.168.138  ESTABLISHED
tunnel2  us-central1           52.44.91.191   ESTABLISHED
```

> Both tunnels should show `ESTABLISHED`. A `WAITING_FOR_FULL_CONFIG` or `FAILED` status usually means the AWS VPN has not yet come up or the pre-shared keys do not match.

**Verify static routes toward AWS**

```bash
gcloud compute routes list \
    --filter="nextHopVpnTunnel:*" \
    --format="table(
        name,
        network.basename():label=VPC,
        destRange:label=DESTINATION_CIDR,
        nextHopVpnTunnel.basename():label=VIA_TUNNEL,
        priority
    )"
```

```console
NAME            VPC         DESTINATION_CIDR  VIA_TUNNEL  PRIORITY
route-cilium-1  gke-cilium  192.168.0.0/16    tunnel1     1000
route-cilium-2  gke-cilium  192.168.0.0/16    tunnel2     1000
```

> Two routes covering `192.168.0.0/16` (the AWS VPC CIDR) via each tunnel provide redundancy.

**List GKE nodes and pod ranges**

```bash
gcloud compute instances list \
    --format="table(
        name,
        networkInterfaces[0].networkIP:label=NODE_IP,
        networkInterfaces[0].subnetwork.basename():label=SUBNET,
        networkInterfaces[0].aliasIpRanges[0].ipCidrRange:label=POD_RANGE
    )"
```

```console
NAME                                           NODE_IP     SUBNET                        POD_RANGE
gke-gke-cilium-gke-cilium-nodes-b5b3d145-hr3k  172.25.1.4  gke-cilium--172--25--1--0-24
```

---

## 6. Blog Post

A detailed write-up of this sandbox — covering the  Cilium Cluster Mesh setup, and the cross-cloud networking deep-dive — is being published on Medium:


## 7. Teardown

Disable Cilium Cluster Mesh on both clusters before destroying infrastructure to avoid stale state:

```bash
cilium clustermesh disable --context eks
cilium clustermesh disable --context gke
kubectl delete -f manifests/bookstore/gateway_api.yaml --context eks
```

Then destroy all Terraform-managed resources:

```bash
terraform destroy
```

---

## 8. Working with kubectl

**Get kubeconfig contexts**

```bash
kubectl config get-contexts
```

**Rename a kubeconfig context**

```bash
kubectl config rename-context <old_context_name> <new_context_name>
```

**Set the default context**

```bash
kubectl config use-context <context_name>
```

**Delete a kubeconfig context**

```bash
kubectl config delete-context <context_name>
```
