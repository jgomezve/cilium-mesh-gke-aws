terraform {
  required_version = ">= 1.6.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.14.1"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.82.2"
    }
  }
}