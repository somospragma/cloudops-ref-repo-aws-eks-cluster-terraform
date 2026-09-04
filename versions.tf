###########################################
# PC-IAC-005 — Alias consumidor aws.project
# PC-IAC-006 — Versiones y Estabilidad
#
# Los Módulos de Referencia NO declaran backend.
# El backend se configura en el Root IaC (sample/ o proyecto raíz).
###########################################

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 5.75.0"
      configuration_aliases = [aws.project]
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0.0"
    }
  }
}
