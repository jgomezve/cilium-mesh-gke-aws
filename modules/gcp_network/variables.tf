variable "name" {
  description = "Network's Name"
  type        = string
}

variable "vpc_auto_mode" {
  description = "VPC in Auto-Mode (Automatically create subnets)"
  type        = bool
  default     = false
}

variable "region" {
  description = "Region for network components (Router, Cloud NAT)"
  type        = string
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
  type        = bool
  default     = true
}

variable "nat_network_options" {
  description = "Option for translation in Cloud NAT"
  type        = string
  default     = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}