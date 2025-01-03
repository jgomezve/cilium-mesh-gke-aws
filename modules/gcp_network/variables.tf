variable "name" {
  description = "Network's Name"
}

variable "vpc_auto_mode" {
  description = "VPC in Auto-Mode (Automatically create subnets)"
  default     = false
  type        = bool
}

variable "region" {
  description = "Region for network components (Router, Cloud NAT)"
}

variable "private_subnets" {
  description = "List of VPC's private subnets"
  type = list(object({
    cidr   = string
    region = string
  }))
}

variable "internet_access" {
  description = "Flag to enable egress Internet access on subnets"
  default     = true
  type        = bool
}

variable "nat_network_options" {
  description = "Option for translation in Cloud NAT"
  default     = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}