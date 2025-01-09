variable "name" {
  description = "GCP VM Name"
  type        = string
}

variable "vpc_name" {
  description = "GCP VPC Name"
  type        = string
}

variable "vpc_id" {
  description = "GCP VPC ID"
  type        = string
}

variable "subnet_id" {
  description = "GCP Subnet ID"
  type        = string
}

variable "vm_type" {
  description = "GCP VM Type"
  type        = string
  default     = "e2-micro"
}

variable "zone" {
  description = "GCP VM Zone"
  type        = string
}

