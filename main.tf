# Cluster EKS
resource "aws_eks_cluster" "this" {
  provider = aws.project
  for_each = var.eks_config
  
  name     = local.cluster_names[each.key].name
  role_arn = each.value.cluster_role_arn
  version  = each.value.kubernetes_version
  
  vpc_config {
    subnet_ids              = each.value.subnet_ids
    security_group_ids      = each.value.cluster_security_group_ids  # Usar directamente la lista
    endpoint_private_access = each.value.endpoint_private_access
    endpoint_public_access  = each.value.endpoint_public_access
    public_access_cidrs     = each.value.endpoint_public_access ? each.value.public_access_cidrs : null
  }
  
  # Configuración de red de Kubernetes
  kubernetes_network_config {
    ip_family         = each.value.ip_family
    service_ipv4_cidr = each.value.service_ipv4_cidr
  }
  
  # Configuración avanzada de acceso
  dynamic "access_config" {
    for_each = each.value.access_config != null ? [each.value.access_config] : []
    
    content {
      authentication_mode                         = access_config.value.authentication_mode
      bootstrap_cluster_creator_admin_permissions = access_config.value.bootstrap_cluster_creator_admin_permissions
    }
  }
  
  # Configuración de cifrado para secretos de Kubernetes
  dynamic "encryption_config" {
    for_each = length(each.value.encryption_config) > 0 ? [1] : []
    
    content {
      provider {
        key_arn = each.value.encryption_config[0].provider_key_arn
      }
      resources = each.value.encryption_config[0].resources
    }
  }
  
  # Configuración de logs
  enabled_cluster_log_types = each.value.create_cloudwatch_log_group ? each.value.cluster_enabled_log_types : []
  
  # Timeouts personalizados
  dynamic "timeouts" {
    for_each = each.value.timeouts != null ? [each.value.timeouts] : []
    
    content {
      create = "${timeouts.value.create}m"
      update = "${timeouts.value.update}m"
      delete = "${timeouts.value.delete}m"
    }
  }
  
  # Asegurar que los recursos dependientes se creen primero
  depends_on = [
    aws_cloudwatch_log_group.this
  ]
  
  # Solo etiquetas adicionales específicas para este recurso
  tags = each.value.additional_tags
}

# Grupo de logs de CloudWatch para el cluster EKS
resource "aws_cloudwatch_log_group" "this" {
  provider = aws.project
  for_each = {
    for k, v in var.eks_config : k => v
    if v.create_cloudwatch_log_group
  }
  
  name              = "/aws/eks/${local.cluster_names[each.key].name}/cluster"
  retention_in_days = each.value.cloudwatch_log_group_retention_in_days
  
  tags = each.value.additional_tags
}

# Proveedor OIDC para el cluster EKS
data "tls_certificate" "cluster" {
  for_each = var.eks_config
  
  depends_on = [aws_eks_cluster.this]
  
  url = aws_eks_cluster.this[each.key].identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "cluster" {
  provider = aws.project
  for_each = var.eks_config
  
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.cluster[each.key].certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.this[each.key].identity[0].oidc[0].issuer
  
  tags = each.value.additional_tags
}
