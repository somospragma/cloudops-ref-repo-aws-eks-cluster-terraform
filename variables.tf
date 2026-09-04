###########################################
# PC-IAC-002 — Variables del Módulo
# PC-IAC-009 — Tipos explícitos + optional()
###########################################

# ─────────────────────────────────────────
# Variables de Gobernanza (Obligatorias)
# ─────────────────────────────────────────

variable "client" {
  description = "Nombre del cliente o unidad de negocio. Usado para construir el nombre del recurso. Solo letras minúsculas, números y guiones."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.client)) && length(var.client) > 0 && length(var.client) <= 10
    error_message = "El valor de 'client' debe contener solo letras minúsculas, números y guiones, con longitud entre 1 y 10 caracteres."
  }
}

variable "project" {
  description = "Nombre del proyecto. Usado para construir el nombre del recurso. Solo letras minúsculas, números y guiones."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project)) && length(var.project) > 0 && length(var.project) <= 15
    error_message = "El valor de 'project' debe contener solo letras minúsculas, números y guiones, con longitud entre 1 y 15 caracteres."
  }
}

variable "environment" {
  description = "Entorno de despliegue. Valores permitidos: dev, qa, pdn."
  type        = string

  validation {
    condition     = contains(["dev", "qa", "pdn"], var.environment)
    error_message = "El valor de 'environment' debe ser uno de: dev, qa, pdn."
  }
}

# ─────────────────────────────────────────
# Configuración Principal de Clusters EKS
# PC-IAC-002 — map(object) para for_each estable
# ─────────────────────────────────────────

variable "eks_config" {
  description = <<-EOT
    Mapa de configuraciones de clusters EKS. Cada clave del mapa es un identificador lógico
    que se usa en el nombre del cluster: {client}-{project}-{env}-eks-{key}.
    Permite crear múltiples clusters en un solo despliegue con configuraciones independientes.
  EOT
  type = map(object({

    # ── Configuración básica ──────────────────────────────────────────────────
    kubernetes_version = string
    # Versión de Kubernetes. Ej: "1.32". Incrementar para upgrade.
    # INMUTABLE la familia (no se puede downgrade). Cambio fuerza update.

    cluster_role_arn = string
    # ARN del IAM Role del plano de control EKS. REQUERIDO.
    # Para Auto Mode debe tener: AmazonEKSClusterPolicy + AmazonEKSComputePolicy
    # + AmazonEKSBlockStoragePolicy + AmazonEKSLoadBalancingPolicy + AmazonEKSNetworkingPolicy

    subnet_ids = list(string)
    # Lista de subnet IDs. Mínimo 2 en zonas de disponibilidad diferentes.
    # Para Auto Mode se recomienda subnets privadas.

    security_group_ids = optional(list(string), [])
    # SGs adicionales para las ENIs del plano de control.
    # EKS crea su propio cluster_security_group_id automáticamente (computed).

    # ── Acceso al endpoint ────────────────────────────────────────────────────
    endpoint_private_access = optional(bool, true)
    # Habilita el endpoint privado del API server. Default: true (best practice).

    endpoint_public_access = optional(bool, false)
    # Habilita el endpoint público del API server. Default: false (best practice).
    # Si true, limitar con public_access_cidrs.

    public_access_cidrs = optional(list(string), ["0.0.0.0/0"])
    # CIDRs que pueden acceder al endpoint público. Solo aplica si endpoint_public_access = true.

    control_plane_egress_mode = optional(string, "AWS_MANAGED")
    # Modo de egreso del plano de control. Valores: AWS_MANAGED (default), CUSTOMER_ROUTED.
    # INMUTABLE: cambiar de CUSTOMER_ROUTED a AWS_MANAGED fuerza recreación del cluster.

    # ── Red de Kubernetes ─────────────────────────────────────────────────────
    ip_family = optional(string, "ipv4")
    # Familia IP para pods y servicios. Valores: ipv4 (default), ipv6.
    # INMUTABLE post-creación del cluster.

    service_ipv4_cidr = optional(string, null)
    # CIDR para servicios de Kubernetes. Ej: "172.20.0.0/16".
    # INMUTABLE post-creación. Debe estar en: 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16.
    # Entre /24 y /12. No debe solapar con la VPC.

    elastic_load_balancing_enabled = optional(bool, false)
    # Habilita la capacidad de ELB en Auto Mode. DEBE ser true cuando Auto Mode está habilitado.
    # Nota: compute_config.enabled + elastic_load_balancing_enabled + block_storage_enabled
    # deben estar TODOS en true o TODOS en false.

    # ── Auto Mode (EKS Compute) ───────────────────────────────────────────────
    compute_config = optional(object({
      enabled    = optional(bool, false)
      node_pools = optional(list(string), ["general-purpose", "system"])
      # node_pools válidos: "general-purpose", "system"
      node_role_arn = optional(string, null)
      # ARN del IAM Role para nodos EC2 gestionados por Auto Mode.
      # INMUTABLE post-habilitación. Debe tener: AmazonEKSWorkerNodeMinimalPolicy
      # + AmazonEC2ContainerRegistryPullOnly
    }), null)

    # ── Storage (Auto Mode) ───────────────────────────────────────────────────
    block_storage_enabled = optional(bool, false)
    # Habilita EBS CSI en Auto Mode. DEBE ser true cuando Auto Mode está habilitado.

    # ── Configuración de Acceso ───────────────────────────────────────────────
    access_config = optional(object({
      authentication_mode = optional(string, "API")
      # Modos: API (solo access entries), API_AND_CONFIG_MAP (ambos), CONFIG_MAP (legacy).
      # Auto Mode requiere API o API_AND_CONFIG_MAP.
      bootstrap_cluster_creator_admin_permissions = optional(bool, true)
      # Otorga permisos de admin al creador del cluster. Default: true.
    }), null)

    # ── Cifrado ───────────────────────────────────────────────────────────────
    encryption_config = optional(list(object({
      provider_key_arn = string
      # ARN de la clave KMS (simétrica, misma región). RECOMENDADO para producción.
      resources = list(string)
      # Recursos a cifrar. Actualmente solo soporta: ["secrets"]
    })), [])

    # ── Protección y Política de Actualización ────────────────────────────────
    deletion_protection = optional(bool, false)
    # Protege el cluster de eliminación accidental. Recomendado: true en producción.

    force_update_version = optional(bool, false)
    # Fuerza el update de versión ignorando checks de readiness. Usar con precaución.

    upgrade_policy = optional(object({
      support_type = optional(string, "EXTENDED")
      # EXTENDED: entra en soporte extendido al final del estándar (más caro pero sin interrupción).
      # STANDARD: se auto-upgradea al final del soporte estándar.
    }), null)

    # ── Control Plane Scaling ─────────────────────────────────────────────────
    control_plane_scaling_config = optional(object({
      tier = optional(string, "standard")
      # Tiers disponibles: standard, tier-xl, tier-2xl, tier-4xl, tier-8xl.
      # tier-xl o mayor requerido para kube_controller_manager_config.horizontal_pod_autoscaler.
    }), null)

    # ── Zonal Shift (ARC) ─────────────────────────────────────────────────────
    zonal_shift_config = optional(object({
      enabled = optional(bool, false)
      # Habilita ARC Zonal Shift para redirigir tráfico multi-AZ durante disrupciones zonales.
      # NO soportado en Auto Mode.
    }), null)

    # ── Kubernetes API Server Config ──────────────────────────────────────────
    kube_api_server_config = optional(object({
      event_ttl = optional(string, null)
      # Duración de retención de eventos K8s. Ej: "1h", "30m". Rango: 10m-60m.
      service_node_port_range = optional(object({
        min_port = optional(number, 30000)
        # Rango: 10260-32767. Default: 30000.
        max_port = optional(number, 32767)
        # Rango: 10260-32767. Default: 32767. Debe ser >= min_port.
      }), null)
    }), null)

    # ── Kubernetes Controller Manager Config ──────────────────────────────────
    kube_controller_manager_config = optional(object({
      horizontal_pod_autoscaler_sync_period = optional(string, null)
      # Intervalo de sync del HPA. Ej: "15s". Rango: 10s-15s.
      # REQUIERE control_plane_scaling_config.tier = tier-xl o mayor.
      terminated_pod_gc_threshold = optional(number, null)
      # Pods terminados antes de que GC los elimine. Rango: 0-12500.
    }), null)

    # ── Kubernetes Scheduler Config ───────────────────────────────────────────
    kube_scheduler_config = optional(object({
      scoring_strategy_type = optional(string, null)
      # Estrategia de scoring: LeastAllocated (default, distribuye carga) o
      # MostAllocated (bin-packing, optimiza costos).
      scoring_resources = optional(list(object({
        name   = string # Ej: "cpu", "memory", "nvidia.com/gpu"
        weight = number # Peso: 1-100
      })), [])
    }), null)

    # ── Hybrid Nodes (Remote Network) ─────────────────────────────────────────
    remote_network_config = optional(object({
      remote_node_cidrs = optional(list(string), [])
      # CIDRs de redes remotas que contienen nodos híbridos.
      remote_pod_cidrs = optional(list(string), [])
      # CIDRs de redes remotas que contienen pods de webhooks en nodos híbridos.
    }), null)

    # ── Logs del Control Plane ────────────────────────────────────────────────
    create_cloudwatch_log_group = optional(bool, true)
    # Crea el Log Group en CloudWatch para los logs del control plane. Default: true.

    cloudwatch_log_group_retention_in_days = optional(number, 90)
    # Retención de logs en días. Default: 90. 0 = nunca expira.

    cluster_enabled_log_types = optional(list(string), ["api", "audit", "authenticator", "controllerManager", "scheduler"])
    # Tipos de logs del control plane. Todos habilitados por defecto (best practice).

    # ── Timeouts ──────────────────────────────────────────────────────────────
    timeouts = optional(object({
      create = optional(number, 30) # Minutos. Default Terraform: 30m.
      update = optional(number, 60) # Minutos. Default Terraform: 60m.
      delete = optional(number, 15) # Minutos. Default Terraform: 15m.
    }), null)

    # ── Tags ──────────────────────────────────────────────────────────────────
    additional_tags = optional(map(string), {})
    # Tags adicionales para el cluster. Se fusionan con la etiqueta Name (PC-IAC-004).
    # Los tags transversales (Client, Project, Environment) se aplican desde default_tags del provider.
  }))

  # ── Validaciones ──────────────────────────────────────────────────────────

  validation {
    condition     = length(var.eks_config) > 0
    error_message = "Debe proporcionarse al menos una configuración de cluster EKS en 'eks_config'."
  }

  validation {
    condition = alltrue([
      for k, v in var.eks_config : contains(["ipv4", "ipv6"], v.ip_family)
    ])
    error_message = "El valor de 'ip_family' debe ser 'ipv4' o 'ipv6'."
  }

  validation {
    condition = alltrue([
      for k, v in var.eks_config : (
        v.access_config == null ? true :
        contains(["API", "API_AND_CONFIG_MAP", "CONFIG_MAP"], v.access_config.authentication_mode)
      )
    ])
    error_message = "El valor de 'authentication_mode' debe ser: API, API_AND_CONFIG_MAP o CONFIG_MAP."
  }

  validation {
    condition = alltrue([
      for k, v in var.eks_config : (
        v.upgrade_policy == null ? true :
        contains(["EXTENDED", "STANDARD"], v.upgrade_policy.support_type)
      )
    ])
    error_message = "El valor de 'upgrade_policy.support_type' debe ser EXTENDED o STANDARD."
  }

  validation {
    condition = alltrue([
      for k, v in var.eks_config : (
        v.control_plane_scaling_config == null ? true :
        contains(["standard", "tier-xl", "tier-2xl", "tier-4xl", "tier-8xl"], v.control_plane_scaling_config.tier)
      )
    ])
    error_message = "El tier de control_plane_scaling_config debe ser: standard, tier-xl, tier-2xl, tier-4xl o tier-8xl."
  }

  validation {
    condition = alltrue([
      for k, v in var.eks_config : (
        v.control_plane_egress_mode == null ? true :
        contains(["AWS_MANAGED", "CUSTOMER_ROUTED"], v.control_plane_egress_mode)
      )
    ])
    error_message = "El valor de 'control_plane_egress_mode' debe ser AWS_MANAGED o CUSTOMER_ROUTED."
  }

  validation {
    # Validar que Auto Mode tenga los 3 flags alineados: todos true o todos false
    condition = alltrue([
      for k, v in var.eks_config : (
        v.compute_config == null ? true : (
          (v.compute_config.enabled == true && v.elastic_load_balancing_enabled == true && v.block_storage_enabled == true) ||
          (v.compute_config.enabled == false && v.elastic_load_balancing_enabled == false && v.block_storage_enabled == false) ||
          v.compute_config.enabled == false
        )
      )
    ])
    error_message = "Auto Mode requiere que compute_config.enabled, elastic_load_balancing_enabled y block_storage_enabled sean TODOS true o TODOS false."
  }

  validation {
    # Si Auto Mode está habilitado, node_role_arn es obligatorio
    condition = alltrue([
      for k, v in var.eks_config : (
        v.compute_config == null ? true : (
          v.compute_config.enabled == false ? true :
          v.compute_config.node_role_arn != null && length(v.compute_config.node_role_arn) > 0
        )
      )
    ])
    error_message = "Cuando compute_config.enabled = true (Auto Mode), node_role_arn es obligatorio."
  }

  validation {
    condition = alltrue([
      for k, v in var.eks_config : length(v.subnet_ids) >= 2
    ])
    error_message = "Deben especificarse al menos 2 subnet_ids en zonas de disponibilidad diferentes."
  }
}
