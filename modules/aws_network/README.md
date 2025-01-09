<!-- BEGIN_TF_DOCS -->
# Terraform AWS Network

Create full VPC Network including subnets, IGW, NATGW and Route-Tables

## Examples

```hcl
module "aws_vpc" {
  source   = ".."
  name     = "my-vpc"
  vpc_cidr = "192.168.0.0/16"
  public_subnets = [
    {
      cidr = "192.168.91.0/24"
      az   = "us-east-1a"
    },
    {
      cidr = "192.168.92.0/24"
      az   = "us-east-1b"
    }
  ]
  private_subnets = [
    {
      cidr = "192.168.1.0/24"
      az   = "us-east-1a"
    },
    {
      cidr   = "192.168.2.0/24"
      az     = "us-east-1b"
      nat_gw = false
    }
  ]
}
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.6.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.82.2 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.82.2 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_name"></a> [name](#input\_name) | Network's Name | `string` | n/a | yes |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | VPC's CIDR | `string` | n/a | yes |
| <a name="input_enable_dns_hostnames"></a> [enable\_dns\_hostnames](#input\_enable\_dns\_hostnames) | Enable DNS hostname on VPC | `bool` | `true` | no |
| <a name="input_private_subnets"></a> [private\_subnets](#input\_private\_subnets) | List of VPC's private subnets | <pre>list(object({<br>    cidr   = string<br>    az     = string<br>    nat_gw = optional(bool, true)<br>  }))</pre> | n/a | yes |
| <a name="input_public_subnets"></a> [public\_subnets](#input\_public\_subnets) | List of VPC's public subnets | <pre>list(object({<br>    cidr = string<br>    az   = string<br>  }))</pre> | n/a | yes |
| <a name="input_internet_access"></a> [internet\_access](#input\_internet\_access) | Flag to enable egress Internet access on private & public subnets | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | VPC ID |
| <a name="output_vpc_name"></a> [vpc\_name](#output\_vpc\_name) | VPC Name |
| <a name="output_private_subnets_id"></a> [private\_subnets\_id](#output\_private\_subnets\_id) | List of ID of the private subnets |
| <a name="output_private_route_tables_id"></a> [private\_route\_tables\_id](#output\_private\_route\_tables\_id) | List of ID of the private route-tables |

## Resources

| Name | Type |
|------|------|
| [aws_eip.elastic_ip](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_internet_gateway.internet_gw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_nat_gateway.nat_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway) | resource |
| [aws_route_table.route_table_private_subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.route_table_public_subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table_association.route_table_association_private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.route_table_association_public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_subnet.private_subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.public_subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |
<!-- END_TF_DOCS -->