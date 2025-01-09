variable "name" {
  description = "EC2 Name"
  type        = string
}

variable "ami" {
  description = "EC2 AMI"
  type        = string
  default     = "ami-01816d07b1128cd2d"
}

variable "type" {
  description = "EC2 Type"
  type        = string
  default     = "t2.micro"
}

variable "ssh_key_name" {
  description = "SSH on EC2"
  type        = string
}

variable "vpc_id" {
  description = "AWS VPC ID"
  type        = string
}

variable "subnet_id" {
  description = "AWS Subnet ID"
  type        = string
}