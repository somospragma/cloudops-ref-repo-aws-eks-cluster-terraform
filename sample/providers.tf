###########################################
# PC-IAC-004 — default_tags transversales
# PC-IAC-005 — alias "principal" en el Root
# PC-IAC-006 — backend con encrypt = true y use_lockfile
###########################################

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.75.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0.0"
    }
  }

  # PC-IAC-006: Backend con cifrado obligatorio
  # Descomentar y configurar antes de ejecutar en un entorno real:
  # backend "s3" {
  #   bucket       = "pragma-eks-platform-dev-tfstate"
  #   key          = "eks-cluster/terraform.tfstate"
  #   region       = "us-east-1"
  #   encrypt      = true
  #   use_lockfile = true
  # }
}

# PC-IAC-005: Provider principal con alias "principal"
provider "aws" {
  region  = var.region
  alias   = "principal"
  profile = var.aws_profile

  # PC-IAC-005: assume_role para pipelines de despliegue
  # Descomentar en entornos reales con role ARN de despliegue:
  # assume_role {
  #   role_arn = "arn:aws:iam::123456789012:role/pragma-eks-platform-dev-deploy-role"
  # }

  # PC-IAC-004: Tags transversales aplicados a todos los recursos
  default_tags {
    tags = {
      Client      = var.client
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
      Module      = "cloudops-ref-repo-aws-eks-cluster-terraform"
    }
  }
}
