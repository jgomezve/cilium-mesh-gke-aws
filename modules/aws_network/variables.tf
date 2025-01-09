variable "name" {
  description = "Network's Name"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC's CIDR"
  type        = string
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostname on VPC"
  type        = bool
  default     = true
}

variable "private_subnets" {
  description = "List of VPC's private subnets"
  type = list(object({
    cidr   = string
    az     = string
    nat_gw = optional(bool, true)
  }))
}

variable "public_subnets" {
  description = "List of VPC's public subnets"
  type = list(object({
    cidr = string
    az   = string
  }))
}

variable "internet_access" {
  description = "Flag to enable egress Internet access on private & public subnets"
  type        = bool
  default     = true
}