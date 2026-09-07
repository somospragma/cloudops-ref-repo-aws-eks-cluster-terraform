###########################################
# PC-IAC-026 — sample/main.tf SOLO invoca el módulo
#              NO contiene bloques locals{}
#              SIEMPRE consume local.eks_config_transformed (nunca var.*)
###########################################

module "eks_cluster" {
  source = "git::https://github.com/somospragma/cloudops-ref-repo-aws-eks-cluster-terraform.git?ref=feature/init-module-eks-cluster"

  providers = {
    aws.project = aws.principal
  }

  # Variables de gobernanza
  client      = var.client
  project     = var.project
  environment = var.environment

  # PC-IAC-026: consumir el mapa transformado, nunca var.eks_config directamente
  eks_config = local.eks_config_transformed
}
