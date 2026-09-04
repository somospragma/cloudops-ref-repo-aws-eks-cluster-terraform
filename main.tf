###########################################
# PC-IAC-010 — for_each en todos los recursos
# PC-IAC-014 — Bloques dynamic para configuración opcional
# PC-IAC-020 — Hardenizado de seguridad (cifrado, logs, acceso privado)
# PC-IAC-023 — Responsabilidad única: solo cluster EKS, OIDC y CW Logs
#              NO crea IAM Roles, Security Groups, VPC, ni Addons
###########################################

# ─────────────────────────────────────────────────────────────────────────────
# CloudWatch Log Group (se crea ANTES del cluster para el depends_on)
# ─────────────────────────────────────────────────────────────────────────────

resource "aws_cloudwatch_log_group" "this" {
  provider = aws.project

  # Solo se crea si create_cloudwatch_log_group = true (PC-IAC-010)
  for_each = {
    for k, v in var.eks_config : k => v
    if v.create_cloudwatch_log_group
  }

  name              = local.cloudwatch_log_group_names[each.key]
  retention_in_days = each.value.cloudwatch_log_group_retention_in_days

  # PC-IAC-004: Name explícito + merge con additional_tags
  tags = merge(
    { Name = local.cloudwatch_log_group_names[each.key] },
    each.value.additional_tags
  )
}

# ─────────────────────────────────────────────────────────────────────────────
# EKS Cluster
# ─────────────────────────────────────────────────────────────────────────────

resource "aws_eks_cluster" "this" {
  provider = aws.project
  for_each = var.eks_config

  name     = local.cluster_names[each.key].name
  role_arn = each.value.cluster_role_arn
  version  = each.value.kubernetes_version

  # ── Protección de eliminación (PC-IAC-020) ─────────────────────────────────
  deletion_protection = each.value.deletion_protection

  # ── Bootstrap de addons (derivado de Auto Mode en locals) ─────────────────
  bootstrap_self_managed_addons = local.bootstrap_self_managed_addons[each.key]

  # ── Force update de versión ────────────────────────────────────────────────
  force_update_version = each.value.force_update_version

  # ── Configuración de VPC ───────────────────────────────────────────────────
  vpc_config {
    subnet_ids              = each.value.subnet_ids
    security_group_ids      = length(each.value.security_group_ids) > 0 ? each.value.security_group_ids : null
    endpoint_private_access = each.value.endpoint_private_access
    endpoint_public_access  = each.value.endpoint_public_access
    public_access_cidrs     = each.value.endpoint_public_access ? each.value.public_access_cidrs : null
    control_plane_egress_mode = each.value.control_plane_egress_mode
  }

  # ── Configuración de red de Kubernetes ────────────────────────────────────
  kubernetes_network_config {
    ip_family         = each.value.ip_family
    service_ipv4_cidr = each.value.service_ipv4_cidr

    # Elastic Load Balancing — requerido para Auto Mode
    dynamic "elastic_load_balancing" {
      for_each = each.value.elastic_load_balancing_enabled ? [1] : []
      content {
        enabled = true
      }
    }
  }

  # ── Auto Mode (Compute Config) ─────────────────────────────────────────────
  dynamic "compute_config" {
    for_each = each.value.compute_config != null && each.value.compute_config.enabled ? [each.value.compute_config] : []
    content {
      enabled       = compute_config.value.enabled
      node_pools    = compute_config.value.node_pools
      node_role_arn = compute_config.value.node_role_arn
    }
  }

  # ── Storage Config — EBS CSI para Auto Mode ────────────────────────────────
  dynamic "storage_config" {
    for_each = each.value.block_storage_enabled ? [1] : []
    content {
      block_storage {
        enabled = true
      }
    }
  }

  # ── Configuración de Acceso ────────────────────────────────────────────────
  dynamic "access_config" {
    for_each = each.value.access_config != null ? [each.value.access_config] : []
    content {
      authentication_mode                         = access_config.value.authentication_mode
      bootstrap_cluster_creator_admin_permissions = access_config.value.bootstrap_cluster_creator_admin_permissions
    }
  }

  # ── Cifrado de Secrets con KMS (PC-IAC-020) ────────────────────────────────
  dynamic "encryption_config" {
    for_each = length(each.value.encryption_config) > 0 ? [each.value.encryption_config[0]] : []
    content {
      provider {
        key_arn = encryption_config.value.provider_key_arn
      }
      resources = encryption_config.value.resources
    }
  }

  # ── Política de Upgrade ────────────────────────────────────────────────────
  dynamic "upgrade_policy" {
    for_each = each.value.upgrade_policy != null ? [each.value.upgrade_policy] : []
    content {
      support_type = upgrade_policy.value.support_type
    }
  }

  # ── Control Plane Scaling ──────────────────────────────────────────────────
  dynamic "control_plane_scaling_config" {
    for_each = each.value.control_plane_scaling_config != null ? [each.value.control_plane_scaling_config] : []
    content {
      tier = control_plane_scaling_config.value.tier
    }
  }

  # ── Zonal Shift (ARC) — NO soportado en Auto Mode ─────────────────────────
  dynamic "zonal_shift_config" {
    for_each = each.value.zonal_shift_config != null ? [each.value.zonal_shift_config] : []
    content {
      enabled = zonal_shift_config.value.enabled
    }
  }

  # ── Kubernetes API Server Config ───────────────────────────────────────────
  dynamic "kube_api_server_config" {
    for_each = each.value.kube_api_server_config != null ? [each.value.kube_api_server_config] : []
    content {
      event_ttl = kube_api_server_config.value.event_ttl

      dynamic "service_node_port_range" {
        for_each = kube_api_server_config.value.service_node_port_range != null ? [kube_api_server_config.value.service_node_port_range] : []
        content {
          min_port = service_node_port_range.value.min_port
          max_port = service_node_port_range.value.max_port
        }
      }
    }
  }

  # ── Kubernetes Controller Manager Config ───────────────────────────────────
  dynamic "kube_controller_manager_config" {
    for_each = each.value.kube_controller_manager_config != null ? [each.value.kube_controller_manager_config] : []
    content {
      dynamic "horizontal_pod_autoscaler_controller_config" {
        for_each = kube_controller_manager_config.value.horizontal_pod_autoscaler_sync_period != null ? [1] : []
        content {
          horizontal_pod_autoscaler_sync_period = kube_controller_manager_config.value.horizontal_pod_autoscaler_sync_period
        }
      }

      dynamic "pod_gc_controller_config" {
        for_each = kube_controller_manager_config.value.terminated_pod_gc_threshold != null ? [1] : []
        content {
          terminated_pod_gc_threshold = kube_controller_manager_config.value.terminated_pod_gc_threshold
        }
      }
    }
  }

  # ── Kubernetes Scheduler Config ────────────────────────────────────────────
  dynamic "kube_scheduler_config" {
    for_each = each.value.kube_scheduler_config != null ? [each.value.kube_scheduler_config] : []
    content {
      dynamic "node_resources_fit" {
        for_each = kube_scheduler_config.value.scoring_strategy_type != null ? [1] : []
        content {
          scoring_strategy {
            type = kube_scheduler_config.value.scoring_strategy_type

            dynamic "resource" {
              for_each = kube_scheduler_config.value.scoring_resources
              content {
                name   = resource.value.name
                weight = resource.value.weight
              }
            }
          }
        }
      }
    }
  }

  # ── Hybrid Nodes (Remote Network Config) ──────────────────────────────────
  dynamic "remote_network_config" {
    for_each = each.value.remote_network_config != null ? [each.value.remote_network_config] : []
    content {
      dynamic "remote_node_networks" {
        for_each = length(remote_network_config.value.remote_node_cidrs) > 0 ? [1] : []
        content {
          cidrs = remote_network_config.value.remote_node_cidrs
        }
      }

      dynamic "remote_pod_networks" {
        for_each = length(remote_network_config.value.remote_pod_cidrs) > 0 ? [1] : []
        content {
          cidrs = remote_network_config.value.remote_pod_cidrs
        }
      }
    }
  }

  # ── Logs del Control Plane (PC-IAC-020: todos los tipos habilitados) ────────
  enabled_cluster_log_types = each.value.create_cloudwatch_log_group ? each.value.cluster_enabled_log_types : []

  # ── Timeouts ───────────────────────────────────────────────────────────────
  dynamic "timeouts" {
    for_each = each.value.timeouts != null ? [each.value.timeouts] : []
    content {
      create = "${timeouts.value.create}m"
      update = "${timeouts.value.update}m"
      delete = "${timeouts.value.delete}m"
    }
  }

  # PC-IAC-004: Name explícito + merge con additional_tags
  tags = merge(
    { Name = local.cluster_names[each.key].name },
    each.value.additional_tags
  )

  # El Log Group debe existir antes de que EKS intente escribir en él
  depends_on = [
    aws_cloudwatch_log_group.this
  ]
}

# ─────────────────────────────────────────────────────────────────────────────
# OIDC Provider — necesario para IRSA y Pod Identity
# PC-IAC-011: data "tls_certificate" se mantiene como data source interno
#             ya que es genérico (no consulta recursos específicos de la cuenta)
# ─────────────────────────────────────────────────────────────────────────────

data "tls_certificate" "cluster" {
  for_each = var.eks_config

  url = aws_eks_cluster.this[each.key].identity[0].oidc[0].issuer

  depends_on = [aws_eks_cluster.this]
}

resource "aws_iam_openid_connect_provider" "cluster" {
  provider = aws.project
  for_each = var.eks_config

  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.cluster[each.key].certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.this[each.key].identity[0].oidc[0].issuer

  # PC-IAC-004: Name explícito + merge con additional_tags
  tags = merge(
    { Name = "${local.cluster_names[each.key].name}-oidc" },
    each.value.additional_tags
  )
}
