locals {
  # Generar nombres de clusters de forma consistente
  cluster_names = {
    for k, v in var.eks_config : k => {
      name = "${var.client}-${var.project}-${var.environment}-eks-${k}"
    }
  }
}
