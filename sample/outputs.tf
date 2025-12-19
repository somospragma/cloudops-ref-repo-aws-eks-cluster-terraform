############################################################################
# Outputs del módulo EKS Cluster
############################################################################

output "cluster_ids" {
  description = "IDs de los clusters EKS"
  value       = module.eks_cluster.cluster_ids
}

output "cluster_arns" {
  description = "ARNs de los clusters EKS"
  value       = module.eks_cluster.cluster_arns
}

output "cluster_names" {
  description = "Nombres de los clusters EKS"
  value       = module.eks_cluster.cluster_names
}

output "cluster_endpoints" {
  description = "Endpoints para los planos de control de EKS"
  value       = module.eks_cluster.cluster_endpoints
}

output "cluster_certificate_authority_data" {
  description = "Datos de los certificados de autoridad de los clusters EKS"
  value       = module.eks_cluster.cluster_certificate_authority_data
  sensitive   = true
}

output "cluster_security_group_ids" {
  description = "IDs de los grupos de seguridad adjuntos a los clusters EKS"
  value       = module.eks_cluster.cluster_security_group_ids
}

output "cluster_versions" {
  description = "Versiones de Kubernetes de los clusters EKS"
  value       = module.eks_cluster.cluster_versions
}

output "cluster_oidc_issuer_urls" {
  description = "URLs de los emisores OIDC de los clusters EKS"
  value       = module.eks_cluster.cluster_oidc_issuer_urls
}

output "oidc_provider_arns" {
  description = "ARNs de los proveedores OIDC"
  value       = module.eks_cluster.oidc_provider_arns
}
