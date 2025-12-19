######################################################################
# Variables Globales
######################################################################
variable "region" {
  description = "Región AWS donde se desplegará el cluster"
  type        = string
  default     = "us-east-1"
}

variable "client" {
  description = "Nombre del cliente"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.client))
    error_message = "El nombre del cliente debe contener solo letras minúsculas, números y guiones."
  }
}

variable "project" {
  description = "Nombre del proyecto"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project))
    error_message = "El nombre del proyecto debe contener solo letras minúsculas, números y guiones."
  }
}

variable "environment" {
  description = "Entorno de despliegue (dev, qa, pdn)"
  type        = string
  validation {
    condition     = contains(["dev", "qa", "pdn"], var.environment)
    error_message = "El entorno debe ser uno de: dev, qa, pdn."
  }
}

######################################################################
# Variables EKS Cluster
######################################################################
variable "eks_config" {
  description = "Configuración de clusters EKS"
  type = map(object({
    # Configuración básica
    kubernetes_version         = string
    vpc_id                     = string
    subnet_ids                 = list(string)
    cluster_role_arn           = string
    cluster_security_group_ids = list(string)

    # Configuración de acceso al endpoint
    endpoint_private_access = optional(bool, true)
    endpoint_public_access  = optional(bool, false)
    public_access_cidrs     = optional(list(string), ["0.0.0.0/0"])

    # Configuración de red de Kubernetes
    ip_family         = optional(string, "ipv4")
    service_ipv4_cidr = optional(string, null)

    # Configuración avanzada de acceso
    access_config = optional(object({
      authentication_mode                         = optional(string, "API")
      bootstrap_cluster_creator_admin_permissions = optional(bool, true)
    }), null)

    # Configuración de Auto Mode
    compute_config = optional(object({
      enabled       = optional(bool, false)
      node_pools    = optional(list(string), ["general-purpose", "system"])
      node_role_arn = optional(string, null)
    }), null)

    # Configuración de cifrado
    encryption_config = list(object({
      provider_key_arn = string
      resources        = list(string)
    }))

    # Configuración de logs
    create_cloudwatch_log_group            = optional(bool, true)
    cloudwatch_log_group_retention_in_days = optional(number, 90)
    cluster_enabled_log_types              = optional(list(string), ["api", "audit", "authenticator", "controllerManager", "scheduler"])

    # Timeouts personalizados (en minutos)
    timeouts = optional(object({
      create = optional(number, 30)
      update = optional(number, 60)
      delete = optional(number, 15)
    }), null)

    # Etiquetas adicionales
    additional_tags = optional(map(string), {})
  }))
  default = {}
}
