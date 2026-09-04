###########################################
# PC-IAC-007 — Outputs del sample para validar el despliegue
###########################################

output "cluster_names" {
  description = "Nombres de los clusters EKS desplegados."
  value       = module.eks_cluster.cluster_names
}

output "cluster_arns" {
  description = "ARNs de los clusters EKS desplegados."
  value       = module.eks_cluster.cluster_arns
}

output "cluster_endpoints" {
  description = "Endpoints del API server de los clusters EKS."
  value       = module.eks_cluster.cluster_endpoints
}

output "cluster_versions" {
  description = "Versiones de Kubernetes de los clusters desplegados."
  value       = module.eks_cluster.cluster_versions
}

output "cluster_statuses" {
  description = "Estados de los clusters EKS (CREATING, ACTIVE, DELETING, FAILED)."
  value       = module.eks_cluster.cluster_statuses
}

output "cluster_security_group_ids" {
  description = "IDs de los Security Groups creados automáticamente por EKS."
  value       = module.eks_cluster.cluster_security_group_ids
}

output "oidc_provider_arns" {
  description = "ARNs de los OIDC Providers. Usar en módulos de addons para configurar IRSA."
  value       = module.eks_cluster.oidc_provider_arns
}

output "cluster_oidc_issuer_urls" {
  description = "URLs del emisor OIDC. Usar para configurar trust policies de IAM roles."
  value       = module.eks_cluster.cluster_oidc_issuer_urls
}

output "cloudwatch_log_group_names" {
  description = "Nombres de los Log Groups de CloudWatch del control plane."
  value       = module.eks_cluster.cloudwatch_log_group_names
}

output "cluster_certificate_authority_data" {
  description = "Certificado CA del cluster (base64). Usar para configurar kubeconfig."
  value       = module.eks_cluster.cluster_certificate_authority_data
  sensitive   = true
}
