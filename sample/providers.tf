######################################################################
# Configuracion Providers AWS
######################################################################
provider "aws" {
  region = var.region
  alias  = "principal"
  
  default_tags {
    tags = {
      client      = var.client
      project     = var.project
      environment = var.environment
      provisioned = "terraform"
      module      = "eks-cluster-sample"
    }
  }
}

######################################################################
# Configuracion Providers Terraform
######################################################################
terraform {
  required_version = ">= 1.10.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.31.0"
    }
  }
}
