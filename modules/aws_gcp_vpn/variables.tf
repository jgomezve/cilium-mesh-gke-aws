variable "name" {
  description = "VPNs Name"
  type        = string
}

variable "region" {
  description = "GCP's Region"
  type        = string
}
variable "aws_vpc_name" {
  description = "AWS VPC Name"
  type        = string
}

variable "gcp_vpc_name" {
  description = "GCP VPC Name"
  type        = string
}

variable "aws_route_tables_ids" {
  description = "AWS Route Table Ids"
  type        = list(string)
}
variable "bgp_asn" {
  description = "AWS BGP ASN"
  type        = number
  default     = 6500
}

variable "ike_version" {
  description = "IKE version for Tunnel. Either `1` or `2`"
  default     = 1
  type        = number
}

variable "gcp_forwarding_rules" {
  description = "Forwarding rules tunnel GCP"
  type = list(object({
    protocol = string
    port     = optional(string, "")
  }))
  default = [
    {
      protocol = "ESP"
    },
    {
      protocol = "UDP"
      port     = "4500"
    },
    {
      protocol = "UDP"
      port     = "500"
    }
  ]
}

variable "cidr_gcp" {
  description = "CIDR on GCP"
  type        = string
}

variable "cidr_aws" {
  description = "CIDR on AWS"
  type        = string
}