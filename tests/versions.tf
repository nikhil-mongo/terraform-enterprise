terraform {
  required_version = ">= 0.13"
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    mongodbatlas = {
      source  = "mongodb/mongodbatlas"
      #version = "~>0.9"
    #   version = "~>1.0"
    }
  }
  terraform {
  cloud {
    organization = "terraform-atlas"
    workspaces {
      name = "terraform-enterprise"
    }
  }
}
