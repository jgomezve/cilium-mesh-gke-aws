variable "name" {
  description = "VPNs Name"

}

variable "region" {
  description = "GCP's Region"
}
variable "vpc_id" {
  description = "AWS VPC ID"
}

variable "bgp_asn" {
  description = "AWS BGP ASN"
  default     = 6500
  type        = number
}