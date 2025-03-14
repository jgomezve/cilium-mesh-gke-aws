variable "name" {
  description = "Cluster's Name"
  type        = string
}

variable "location" {
  description = "GKE location. Either a region or a zone"
  type        = string
}

variable "gke_vpc_name" {
  description = "Name of VPC for the GKE cluster"
  type        = string
}

variable "gke_vpc_id" {
  description = "ID of VPC for the GKE cluster"
  type        = string
}

variable "gke_subnet_id" {
  description = "ID of subnet for the GKE cluster"
  type        = string
}

variable "pod_cidr" {
  description = "GKE Pod CIDR"
  type        = string
}

variable "nodes_type" {
  description = "Type of VM for worker nodes"
  type        = string
  default     = "e2-small"
}

variable "minimum_nodes" {
  description = "Minimum number of nodes in cluster"
  type        = number
  default     = 1
}

variable "maximum_nodes" {
  description = "Maximum number of nodes in cluster"
  type        = number
  default     = 1
}


variable "private_cluser" {
  description = "Flag to have enable/disable external IPs on workers"
  type        = bool
  default     = true
}