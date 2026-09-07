###########################################
# PC-IAC-002 — Variables del sample/
# PC-IAC-026 — Variables reciben la configuración base de terraform.tfvars
###########################################

variable "client" {
  description = "Nombre del cliente. Solo letras minúsculas, números y guiones (max 10 chars)."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.client)) && length(var.client) > 0 && length(var.client) <= 10
    error_message = "El valor de 'client' debe contener solo letras minúsculas, números y guiones, max 10 caracteres."
  }
}

variable "project" {
  description = "Nombre del proyecto. Solo letras minúsculas, números y guiones (max 15 chars)."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project)) && length(var.project) > 0 && length(var.project) <= 15
    error_message = "El valor de 'project' debe contener solo letras minúsculas, números y guiones, max 15 caracteres."
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

variable "region" {
  description = "Región AWS donde se desplegará el cluster EKS."
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "Perfil AWS CLI para autenticación. Debe tener permisos de EKS, IAM, KMS, CloudWatch."
  type        = string
  default     = "default"
}

variable "eks_config" {
  description = <<-EOT
    Configuración base de los clusters EKS. Los campos con valores vacíos ("", [])
    son completados con IDs dinámicos obtenidos de data sources en locals.tf.
    Ver sample/locals.tf para el patrón de transformación (PC-IAC-026).
  EOT
  type = map(object({
    kubernetes_version              = string
    cluster_role_arn                = optional(string, "")
    subnet_ids                      = optional(list(string), [])
    security_group_ids              = optional(list(string), [])
    endpoint_private_access         = optional(bool, true)
    endpoint_public_access          = optional(bool, false)
    public_access_cidrs             = optional(list(string), ["0.0.0.0/0"])
    control_plane_egress_mode       = optional(string, "AWS_MANAGED")
    ip_family                       = optional(string, "ipv4")
    service_ipv4_cidr               = optional(string, null)
    elastic_load_balancing_enabled  = optional(bool, false)
    compute_config = optional(object({
      enabled       = optional(bool, false)
      node_pools    = optional(list(string), ["general-purpose", "system"])
      node_role_arn = optional(string, null)
    }), null)
    block_storage_enabled = optional(bool, false)
    access_config = optional(object({
      authentication_mode                         = optional(string, "API")
      bootstrap_cluster_creator_admin_permissions = optional(bool, true)
    }), null)
    deletion_protection    = optional(bool, false)
    force_update_version   = optional(bool, false)
    upgrade_policy = optional(object({
      support_type = optional(string, "EXTENDED")
    }), null)
    control_plane_scaling_config = optional(object({
      tier = optional(string, "standard")
    }), null)
    zonal_shift_config = optional(object({
      enabled = optional(bool, false)
    }), null)
    kube_api_server_config = optional(object({
      event_ttl = optional(string, null)
      service_node_port_range = optional(object({
        min_port = optional(number, 30000)
        max_port = optional(number, 32767)
      }), null)
    }), null)
    kube_controller_manager_config = optional(object({
      horizontal_pod_autoscaler_sync_period = optional(string, null)
      terminated_pod_gc_threshold           = optional(number, null)
    }), null)
    kube_scheduler_config = optional(object({
      scoring_strategy_type = optional(string, null)
      scoring_resources = optional(list(object({
        name   = string
        weight = number
      })), [])
    }), null)
    remote_network_config = optional(object({
      remote_node_cidrs = optional(list(string), [])
      remote_pod_cidrs  = optional(list(string), [])
    }), null)
    create_cloudwatch_log_group            = optional(bool, true)
    cloudwatch_log_group_retention_in_days = optional(number, 90)
    cluster_enabled_log_types              = optional(list(string), ["api", "audit", "authenticator", "controllerManager", "scheduler"])
    timeouts = optional(object({
      create = optional(number, 30)
      update = optional(number, 60)
      delete = optional(number, 15)
    }), null)
    additional_tags = optional(map(string), {})
  }))

  validation {
    condition     = length(var.eks_config) > 0
    error_message = "Debe proporcionarse al menos una configuración en eks_config."
  }
}
