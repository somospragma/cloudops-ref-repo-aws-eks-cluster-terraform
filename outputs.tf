###########################################
# PC-IAC-007 — Outputs granulares (solo IDs/ARNs, no objetos completos)
# PC-IAC-014 — Splat expressions con values()[*]
###########################################

# ─────────────────────────────────────────
# Cluster EKS — Identificadores
# ─────────────────────────────────────────

output "cluster_names" {
  description = "Mapa de nombres de los clusters EKS. Clave = key del mapa eks_config, valor = nombre del cluster."
  value = {
    for k, v in aws_eks_cluster.this : k => v.name
  }
}

output "cluster_ids" {
  description = "Mapa de IDs de los clusters EKS (equivalente al nombre del cluster en EKS)."
  value = {
    for k, v in aws_eks_cluster.this : k => v.id
  }
}

output "cluster_arns" {
  description = "Mapa de ARNs de los clusters EKS."
  value = {
    for k, v in aws_eks_cluster.this : k => v.arn
  }
}

# ─────────────────────────────────────────
# Cluster EKS — Conectividad
# ─────────────────────────────────────────

output "cluster_endpoints" {
  description = "Mapa de endpoints del API server de los clusters EKS."
  value = {
    for k, v in aws_eks_cluster.this : k => v.endpoint
  }
}

output "cluster_certificate_authority_data" {
  description = "Mapa con el certificado de autoridad (base64) de cada cluster EKS. Usado para configurar kubeconfig."
  value = {
    for k, v in aws_eks_cluster.this : k => v.certificate_authority[0].data
  }
}

# ─────────────────────────────────────────
# Cluster EKS — Versión y Estado
# ─────────────────────────────────────────

output "cluster_versions" {
  description = "Mapa de versiones de Kubernetes de los clusters EKS."
  value = {
    for k, v in aws_eks_cluster.this : k => v.version
  }
}

output "cluster_platform_versions" {
  description = "Mapa de versiones de plataforma EKS (ej: eks.5). Indica la versión interna de la plataforma."
  value = {
    for k, v in aws_eks_cluster.this : k => v.platform_version
  }
}

output "cluster_statuses" {
  description = "Mapa de estados de los clusters EKS. Valores: CREATING, ACTIVE, DELETING, FAILED."
  value = {
    for k, v in aws_eks_cluster.this : k => v.status
  }
}

output "cluster_created_at" {
  description = "Mapa de timestamps Unix (segundos) de creación de los clusters EKS."
  value = {
    for k, v in aws_eks_cluster.this : k => v.created_at
  }
}

# ─────────────────────────────────────────
# Cluster EKS — Networking
# ─────────────────────────────────────────

output "cluster_security_group_ids" {
  description = "Mapa de IDs del Security Group creado automáticamente por EKS para la comunicación control plane ↔ data plane."
  value = {
    for k, v in aws_eks_cluster.this : k => v.vpc_config[0].cluster_security_group_id
  }
}

output "cluster_vpc_ids" {
  description = "Mapa de IDs de la VPC asociada a cada cluster EKS."
  value = {
    for k, v in aws_eks_cluster.this : k => v.vpc_config[0].vpc_id
  }
}

# ─────────────────────────────────────────
# OIDC Provider — para IRSA y Pod Identity
# ─────────────────────────────────────────

output "cluster_oidc_issuer_urls" {
  description = "Mapa de URLs del emisor OIDC de cada cluster EKS. Usado para configurar IRSA."
  value = {
    for k, v in aws_eks_cluster.this : k => v.identity[0].oidc[0].issuer
  }
}

output "oidc_provider_arns" {
  description = "Mapa de ARNs de los OIDC Providers de IAM creados para cada cluster. Usado para configurar IRSA en módulos de addons."
  value = {
    for k, v in aws_iam_openid_connect_provider.cluster : k => v.arn
  }
}

output "oidc_provider_urls" {
  description = "Mapa de URLs de los OIDC Providers (sin prefijo https://). Usado en condiciones de trust policy de IAM roles."
  value = {
    for k, v in aws_iam_openid_connect_provider.cluster : k => v.url
  }
}

# ─────────────────────────────────────────
# CloudWatch Log Groups
# ─────────────────────────────────────────

output "cloudwatch_log_group_names" {
  description = "Mapa de nombres de los Log Groups de CloudWatch creados para los logs del control plane de cada cluster."
  value = {
    for k, v in aws_cloudwatch_log_group.this : k => v.name
  }
}

output "cloudwatch_log_group_arns" {
  description = "Mapa de ARNs de los Log Groups de CloudWatch de cada cluster EKS."
  value = {
    for k, v in aws_cloudwatch_log_group.this : k => v.arn
  }
}
