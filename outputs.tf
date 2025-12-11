output "cluster_ids" {
  description = "IDs de los clusters EKS"
  value = {
    for k, v in aws_eks_cluster.this : k => v.id
  }
}

output "cluster_arns" {
  description = "ARNs de los clusters EKS"
  value = {
    for k, v in aws_eks_cluster.this : k => v.arn
  }
}

output "cluster_names" {
  description = "Nombres de los clusters EKS"
  value = {
    for k, v in aws_eks_cluster.this : k => v.name
  }
}

output "cluster_endpoints" {
  description = "Endpoints para los planos de control de EKS"
  value = {
    for k, v in aws_eks_cluster.this : k => v.endpoint
  }
}

output "cluster_certificate_authority_data" {
  description = "Datos de los certificados de autoridad de los clusters EKS"
  value = {
    for k, v in aws_eks_cluster.this : k => v.certificate_authority[0].data
  }
}

output "cluster_security_group_ids" {
  description = "IDs de los grupos de seguridad adjuntos a los clusters EKS"
  value = {
    for k, v in aws_eks_cluster.this : k => v.vpc_config[0].cluster_security_group_id
  }
}

output "cluster_versions" {
  description = "Versiones de Kubernetes de los clusters EKS"
  value = {
    for k, v in aws_eks_cluster.this : k => v.version
  }
}

output "cluster_oidc_issuer_urls" {
  description = "URLs de los emisores OIDC de los clusters EKS"
  value = {
    for k, v in aws_eks_cluster.this : k => v.identity[0].oidc[0].issuer
  }
}

output "oidc_provider_arns" {
  description = "ARNs de los proveedores OIDC"
  value = {
    for k, v in aws_iam_openid_connect_provider.cluster : k => v.arn
  }
}
