############################################################################
# Sample - EKS Cluster Module
############################################################################

module "eks_cluster" {
  source = "../"
  
  providers = {
    aws.project = aws.principal
  }

  # Variables obligatorias de nomenclatura
  client      = var.client
  project     = var.project
  environment = var.environment
  
  # Configuración de clusters EKS con recursos dinámicos
  eks_config = local.eks_config_with_resources
}
