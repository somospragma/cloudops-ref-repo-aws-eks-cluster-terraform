variable "eks_config" {
  description = "Configuración de clusters EKS"
  type = map(object({
    # Configuración básica
    kubernetes_version      = string
    vpc_id                  = string
    subnet_ids              = list(string)
    cluster_role_arn        = string
    cluster_security_group_ids = list(string)  # Lista de IDs de grupos de seguridad
    
    # Configuración de acceso al endpoint
    endpoint_private_access = optional(bool, true)
    endpoint_public_access  = optional(bool, false)
    public_access_cidrs     = optional(list(string), ["0.0.0.0/0"])
    
    # Configuración de red de Kubernetes
    ip_family               = optional(string, "ipv4")  # Opciones: ipv4 o ipv6
    service_ipv4_cidr       = optional(string, null)    # Personalizar CIDR para servicios (ej: "172.20.0.0/16")
    
    # Configuración avanzada de acceso
    access_config = optional(object({
      authentication_mode                         = optional(string, "API")  # API o API_AND_CONFIG_MAP
      bootstrap_cluster_creator_admin_permissions = optional(bool, true)
    }), null)
    
    # Configuración de Auto Mode (EKS Compute)
    compute_config = optional(object({
      enabled       = optional(bool, false)
      node_pools    = optional(list(string), ["general-purpose", "system"])
      node_role_arn = optional(string, null)
    }), null)
    
    # Configuración de Kubernetes Networking (requerido para Auto Mode)
    kubernetes_network_config = optional(object({
      elastic_load_balancing = optional(object({
        enabled = optional(bool, false)
      }), null)
    }), null)
    
    # Configuración de Storage (requerido para Auto Mode)
    storage_config = optional(object({
      block_storage = optional(object({
        enabled = optional(bool, false)
      }), null)
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
  
  validation {
    condition     = length(var.eks_config) > 0
    error_message = "Al menos una configuración de cluster EKS debe ser proporcionada."
  }
  
  validation {
    condition = alltrue([
      for k, v in var.eks_config : contains(["ipv4", "ipv6"], v.ip_family)
    ])
    error_message = "El valor de ip_family debe ser 'ipv4' o 'ipv6'."
  }
}

variable "client" {
  description = "Nombre del cliente para el que se crea el recurso"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.client))
    error_message = "El nombre del cliente debe contener solo letras minúsculas, números y guiones."
  }
}

variable "project" {
  description = "Nombre del proyecto o funcionalidad"
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