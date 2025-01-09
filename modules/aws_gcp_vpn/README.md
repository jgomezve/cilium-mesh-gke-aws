<!-- BEGIN_TF_DOCS -->
# Terraform AWS GCP Site-to-Site VPN

Create a classic VPN between Amazon Web Services an Google Cloud Platform using static routes

## Examples

```hcl
module "aws_gcp_vpn" {
  source               = "../"
  aws_vpc_name         = "aws-vpc"
  gcp_vpc_name         = "gcp-vpc"
  name                 = "cilium"
  cidr_gcp             = "172.25.1.0/24"
  cidr_aws             = "192.168.0.0/16"
  aws_route_tables_ids = [aws_route_table.default.id]
  region               = "us-central1"
}
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.6.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.82.2 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 6.14.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | >= 6.14.1 |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.82.2 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_name"></a> [name](#input\_name) | VPNs Name | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | GCP's Region | `string` | n/a | yes |
| <a name="input_aws_vpc_name"></a> [aws\_vpc\_name](#input\_aws\_vpc\_name) | AWS VPC Name | `string` | n/a | yes |
| <a name="input_gcp_vpc_name"></a> [gcp\_vpc\_name](#input\_gcp\_vpc\_name) | GCP VPC Name | `string` | n/a | yes |
| <a name="input_aws_route_tables_ids"></a> [aws\_route\_tables\_ids](#input\_aws\_route\_tables\_ids) | AWS Route Table Ids | `list(string)` | n/a | yes |
| <a name="input_bgp_asn"></a> [bgp\_asn](#input\_bgp\_asn) | AWS BGP ASN | `number` | `6500` | no |
| <a name="input_ike_version"></a> [ike\_version](#input\_ike\_version) | IKE version for Tunnel. Either `1` or `2` | `number` | `1` | no |
| <a name="input_gcp_forwarding_rules"></a> [gcp\_forwarding\_rules](#input\_gcp\_forwarding\_rules) | Forwarding rules tunnel GCP | <pre>list(object({<br>    protocol = string<br>    port     = optional(string, "")<br>  }))</pre> | <pre>[<br>  {<br>    "protocol": "ESP"<br>  },<br>  {<br>    "port": "4500",<br>    "protocol": "UDP"<br>  },<br>  {<br>    "port": "500",<br>    "protocol": "UDP"<br>  }<br>]</pre> | no |
| <a name="input_cidr_gcp"></a> [cidr\_gcp](#input\_cidr\_gcp) | CIDR on GCP | `string` | n/a | yes |
| <a name="input_cidr_aws"></a> [cidr\_aws](#input\_cidr\_aws) | CIDR on AWS | `string` | n/a | yes |

## Outputs

No outputs.

## Resources

| Name | Type |
|------|------|
| [aws_customer_gateway.remote_site](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/customer_gateway) | resource |
| [aws_vpn_connection.vpn_connection](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpn_connection) | resource |
| [aws_vpn_connection_route.route_to_gcp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpn_connection_route) | resource |
| [aws_vpn_gateway.vpn_gw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpn_gateway) | resource |
| [aws_vpn_gateway_route_propagation.route_propagation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpn_gateway_route_propagation) | resource |
| [google_compute_address.external_ip_vpn](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_address) | resource |
| [google_compute_forwarding_rule.rule](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_forwarding_rule) | resource |
| [google_compute_route.route_aws](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_route) | resource |
| [google_compute_vpn_gateway.vpn_gw](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_vpn_gateway) | resource |
| [google_compute_vpn_tunnel.tunnel](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_vpn_tunnel) | resource |
| [aws_vpc.aws_vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |
| [google_compute_network.gcp_vpc](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_network) | data source |
<!-- END_TF_DOCS -->