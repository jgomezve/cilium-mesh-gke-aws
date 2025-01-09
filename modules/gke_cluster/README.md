<!-- BEGIN_TF_DOCS -->
# Terraform GKE Cluster

Creates a GKE Cluster and Node Groups

## Examples

```hcl
module "gke_cluster" {
  source        = ".."
  name          = "gke-cluster"
  pod_cidr      = "10.111.0.0/16"
  gke_vpc_id    = google_compute_network.vpc.id
  gke_subnet_id = google_compute_subnetwork.subnet.id
  location      = "us-central1-a"
}
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.6.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 6.14.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | >= 6.14.1 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_name"></a> [name](#input\_name) | Cluster's Name | `string` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | GKE location. Either a region or a zone | `string` | n/a | yes |
| <a name="input_gke_vpc_name"></a> [gke\_vpc\_name](#input\_gke\_vpc\_name) | Name of VPC for the GKE cluster | `string` | n/a | yes |
| <a name="input_gke_vpc_id"></a> [gke\_vpc\_id](#input\_gke\_vpc\_id) | ID of VPC for the GKE cluster | `string` | n/a | yes |
| <a name="input_gke_subnet_id"></a> [gke\_subnet\_id](#input\_gke\_subnet\_id) | ID of subnet for the GKE cluster | `string` | n/a | yes |
| <a name="input_pod_cidr"></a> [pod\_cidr](#input\_pod\_cidr) | GKE Pod CIDR | `string` | n/a | yes |
| <a name="input_nodes_type"></a> [nodes\_type](#input\_nodes\_type) | Type of VM for worker nodes | `string` | `"e2-small"` | no |
| <a name="input_minimum_nodes"></a> [minimum\_nodes](#input\_minimum\_nodes) | Minimum number of nodes in cluster | `number` | `1` | no |
| <a name="input_maximum_nodes"></a> [maximum\_nodes](#input\_maximum\_nodes) | Maximum number of nodes in cluster | `number` | `1` | no |
| <a name="input_private_cluser"></a> [private\_cluser](#input\_private\_cluser) | Flag to have enable/disable external IPs on workers | `bool` | `true` | no |

## Outputs

No outputs.

## Resources

| Name | Type |
|------|------|
| [google_compute_firewall.default_rules](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_container_cluster.cluster](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_cluster) | resource |
| [google_container_node_pool.node_group](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_node_pool) | resource |
<!-- END_TF_DOCS -->