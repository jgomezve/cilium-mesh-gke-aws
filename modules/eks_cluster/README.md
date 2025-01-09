<!-- BEGIN_TF_DOCS -->
# Terraform EKS Cluster

Creates an EKS Cluster, Managed groups and Add Ons

## Examples

```hcl
module "eks_cluster" {
  source                  = ".."
  name                    = "my-cluster"
  ssh_keys_name           = "my-ssh-key"
  eks_vpc_id              = aws_vpc.vpc.id
  eks_cluster_subnets_ids = [aws_subnet.private_subnets.id]
  roles_with_access       = ["arn:aws:iam::00000:user/aws-cli"]
  eks_addons              = ["kube-proxy", "vpc-cni"]
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
| <a name="input_name"></a> [name](#input\_name) | Cluster's Name | `string` | n/a | yes |
| <a name="input_authentication_mode"></a> [authentication\_mode](#input\_authentication\_mode) | EKS Authentication mode | `string` | `"API"` | no |
| <a name="input_eks_version"></a> [eks\_version](#input\_eks\_version) | EKS Version | `string` | `"1.31"` | no |
| <a name="input_private_endpoint"></a> [private\_endpoint](#input\_private\_endpoint) | EKS API private flag | `bool` | `true` | no |
| <a name="input_public_endpoint"></a> [public\_endpoint](#input\_public\_endpoint) | EKS API public flag | `bool` | `true` | no |
| <a name="input_eks_vpc_id"></a> [eks\_vpc\_id](#input\_eks\_vpc\_id) | ID of VPC for the EKS cluster | `string` | n/a | yes |
| <a name="input_eks_cluster_subnets_ids"></a> [eks\_cluster\_subnets\_ids](#input\_eks\_cluster\_subnets\_ids) | List of subnet ids for the EKS cluster. Subnets must be in different AZ | `list(string)` | n/a | yes |
| <a name="input_eks_ec2_cluster_subnets_ids"></a> [eks\_ec2\_cluster\_subnets\_ids](#input\_eks\_ec2\_cluster\_subnets\_ids) | List of subnet ids for the EC2 cluster. Option used to save costs | `list(string)` | `[]` | no |
| <a name="input_eks_addons"></a> [eks\_addons](#input\_eks\_addons) | List of Addons to install on EKS | `list(string)` | <pre>[<br>  "vpc-cni",<br>  "kube-proxy",<br>  "coredns"<br>]</pre> | no |
| <a name="input_minimum_nodes"></a> [minimum\_nodes](#input\_minimum\_nodes) | Minimum number of nodes in cluster | `number` | `1` | no |
| <a name="input_maximum_nodes"></a> [maximum\_nodes](#input\_maximum\_nodes) | Maximum number of nodes in cluster | `number` | `1` | no |
| <a name="input_desired_nodes"></a> [desired\_nodes](#input\_desired\_nodes) | Desired number of nodes in cluster | `number` | `1` | no |
| <a name="input_ssh_keys_name"></a> [ssh\_keys\_name](#input\_ssh\_keys\_name) | Name of SSH keas for the worker nodes | `string` | n/a | yes |
| <a name="input_instance_types"></a> [instance\_types](#input\_instance\_types) | List of desired EC2 instance types for the worker nodes | `list(string)` | <pre>[<br>  "t3.medium"<br>]</pre> | no |
| <a name="input_ami_type"></a> [ami\_type](#input\_ami\_type) | AMI Type for the worker nodes | `string` | `"AL2_x86_64"` | no |
| <a name="input_roles_with_access"></a> [roles\_with\_access](#input\_roles\_with\_access) | List of IAM ARN that can access the cluster | `list(string)` | n/a | yes |
| <a name="input_load_balancer_ctrl_requirements"></a> [load\_balancer\_ctrl\_requirements](#input\_load\_balancer\_ctrl\_requirements) | Flag to create infra required by the AWS Load Balancer Controller | `bool` | `true` | no |

## Outputs

No outputs.

## Resources

| Name | Type |
|------|------|
| [aws_eks_access_entry.access_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_access_entry) | resource |
| [aws_eks_access_policy_association.policy_association](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_access_policy_association) | resource |
| [aws_eks_addon.eks_addon](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon) | resource |
| [aws_eks_cluster.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_cluster) | resource |
| [aws_eks_node_group.node_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_node_group) | resource |
| [aws_iam_role.eks_cluster_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.eks_worker_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.load_balancer_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.ec2_policy_attachment_cr_ro](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.ec2_policy_attachment_eks_cni](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.ec2_policy_attachment_eks_worker](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.eks_cluster_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_launch_template.aws_launch_template](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) | resource |
| [aws_security_group.worker_security_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
<!-- END_TF_DOCS -->