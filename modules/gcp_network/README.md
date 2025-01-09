<!-- BEGIN_TF_DOCS -->
# Terraform GCP VPC

Creates a full VPC network, including routes and Cloud-NAT

## Examples

```hcl
module "gcp_vpc" {
  source = ".."
  name   = "gke-vpc"
  region = "us-central1"
  private_subnets = [
    {
      cidr   = "172.16.1.0/24"
      region = "us-central1"
    }
  ]

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
| <a name="input_name"></a> [name](#input\_name) | Network's Name | `string` | n/a | yes |
| <a name="input_vpc_auto_mode"></a> [vpc\_auto\_mode](#input\_vpc\_auto\_mode) | VPC in Auto-Mode (Automatically create subnets) | `bool` | `false` | no |
| <a name="input_region"></a> [region](#input\_region) | Region for network components (Router, Cloud NAT) | `string` | n/a | yes |
| <a name="input_private_subnets"></a> [private\_subnets](#input\_private\_subnets) | List of VPC's private subnets | <pre>list(object({<br>    cidr   = string<br>    region = string<br>  }))</pre> | n/a | yes |
| <a name="input_internet_access"></a> [internet\_access](#input\_internet\_access) | Flag to enable egress Internet access on subnets | `bool` | `true` | no |
| <a name="input_nat_network_options"></a> [nat\_network\_options](#input\_nat\_network\_options) | Option for translation in Cloud NAT | `string` | `"ALL_SUBNETWORKS_ALL_IP_RANGES"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | VPC ID |
| <a name="output_vpc_name"></a> [vpc\_name](#output\_vpc\_name) | VPC Name |
| <a name="output_private_subnets_id"></a> [private\_subnets\_id](#output\_private\_subnets\_id) | List of IDs of private subnets |

## Resources

| Name | Type |
|------|------|
| [google_compute_network.vpc](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_network) | resource |
| [google_compute_router.router](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router) | resource |
| [google_compute_router_nat.nat](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router_nat) | resource |
| [google_compute_subnetwork.gke_nodes_subnet](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork) | resource |
<!-- END_TF_DOCS -->