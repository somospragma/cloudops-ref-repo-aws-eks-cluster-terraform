# Módulo EKS Cluster

## Propósito

Este módulo crea y gestiona clusters de Amazon Elastic Kubernetes Service (EKS) con configuraciones avanzadas de seguridad, networking y logging. Permite implementar clusters EKS siguiendo las mejores prácticas de AWS y los estándares de nomenclatura y etiquetado.

## Recursos creados

Este módulo crea los siguientes recursos de AWS:

| Recurso | Descripción |
|---------|-------------|
| `aws_eks_cluster` | El cluster EKS principal |
| `aws_cloudwatch_log_group` | Grupo de logs de CloudWatch para los logs del cluster |
| `aws_iam_openid_connect_provider` | Proveedor OIDC para integración con IAM |
| `tls_certificate` | Certificado TLS para el proveedor OIDC |

## Inputs detallados

### Variables principales

| Nombre | Descripción | Tipo | Requerido | Default |
|--------|-------------|------|----------|---------|
| `client` | Nombre del cliente para el que se crea el recurso | `string` | Sí | - |
| `project` | Nombre del proyecto o funcionalidad | `string` | Sí | - |
| `environment` | Entorno de despliegue (dev, qa, pdn) | `string` | Sí | - |
| `eks_config` | Configuración de clusters EKS | `map(object)` | Sí | - |

### Estructura de eks_config

```hcl
eks_config = {
  "cluster_key" = {
    # Configuración básica (obligatoria)
    kubernetes_version      = string
    vpc_id                  = string
    subnet_ids              = list(string)
    cluster_role_arn        = string
    cluster_security_group_ids = list(string)
    
    # Configuración de acceso al endpoint (opcional)
    endpoint_private_access = optional(bool, true)
    endpoint_public_access  = optional(bool, false)
    public_access_cidrs     = optional(list(string), ["0.0.0.0/0"])
    
    # Configuración de red de Kubernetes (opcional)
    ip_family               = optional(string, "ipv4")  # Opciones: ipv4 o ipv6
    service_ipv4_cidr       = optional(string, null)    # Personalizar CIDR para servicios (ej: "172.20.0.0/16")
    
    # Configuración avanzada de acceso (opcional)
    access_config = optional(object({
      authentication_mode                         = optional(string, "API")  # API o API_AND_CONFIG_MAP
      bootstrap_cluster_creator_admin_permissions = optional(bool, true)
    }), null)
    
    # Configuración de cifrado (obligatoria)
    encryption_config = list(object({
      provider_key_arn = string
      resources        = list(string)
    }))
    
    # Configuración de logs (opcional)
    create_cloudwatch_log_group            = optional(bool, true)
    cloudwatch_log_group_retention_in_days = optional(number, 90)
    cluster_enabled_log_types              = optional(list(string), ["api", "audit", "authenticator", "controllerManager", "scheduler"])
    
    # Timeouts personalizados en minutos (opcional)
    timeouts = optional(object({
      create = optional(number, 30)
      update = optional(number, 60)
      delete = optional(number, 15)
    }), null)
    
    # Etiquetas adicionales (opcional)
    additional_tags = optional(map(string), {})
  }
}
```

#### Detalles de los parámetros

##### Configuración básica

- `kubernetes_version`: Versión de Kubernetes para el cluster (ej: "1.28", "1.29")
- `vpc_id`: ID de la VPC donde se creará el cluster
- `subnet_ids`: Lista de IDs de subnets donde se desplegará el cluster (mínimo 2 en diferentes AZs)
- `cluster_role_arn`: ARN del rol IAM que asumirá el cluster
- `cluster_security_group_ids`: Lista de IDs de grupos de seguridad para el cluster

##### Configuración de acceso al endpoint

- `endpoint_private_access`: Habilita el acceso privado al endpoint del API server
- `endpoint_public_access`: Habilita el acceso público al endpoint del API server
- `public_access_cidrs`: Lista de CIDRs permitidos para acceder al endpoint público

##### Configuración de red de Kubernetes

- `ip_family`: Familia de IP para el cluster ("ipv4" o "ipv6")
- `service_ipv4_cidr`: CIDR para servicios de Kubernetes (ej: "172.20.0.0/16")

##### Configuración avanzada de acceso

- `authentication_mode`: Modo de autenticación ("API" o "API_AND_CONFIG_MAP")
- `bootstrap_cluster_creator_admin_permissions`: Otorga permisos de administrador al creador del cluster

##### Configuración de cifrado

- `provider_key_arn`: ARN de la clave KMS para cifrar secretos
- `resources`: Lista de recursos a cifrar (normalmente ["secrets"])

##### Configuración de logs

- `create_cloudwatch_log_group`: Crea un grupo de logs de CloudWatch
- `cloudwatch_log_group_retention_in_days`: Días de retención de logs
- `cluster_enabled_log_types`: Tipos de logs a habilitar

##### Timeouts personalizados

- `create`: Timeout para la creación del cluster (minutos)
- `update`: Timeout para la actualización del cluster (minutos)
- `delete`: Timeout para la eliminación del cluster (minutos)

##### Etiquetas adicionales

- `additional_tags`: Mapa de etiquetas adicionales para el cluster

## Outputs detallados

| Nombre | Descripción | Ejemplo |
|--------|-------------|---------|
| `cluster_ids` | Mapa de IDs de los clusters EKS | `{"main" = "pragma-demo-dev-eks-main"}` |
| `cluster_arns` | Mapa de ARNs de los clusters EKS | `{"main" = "arn:aws:eks:us-east-1:123456789012:cluster/pragma-demo-dev-eks-main"}` |
| `cluster_names` | Mapa de nombres de los clusters EKS | `{"main" = "pragma-demo-dev-eks-main"}` |
| `cluster_endpoints` | Mapa de endpoints para los planos de control de EKS | `{"main" = "https://1234567890ABCDEF.gr7.us-east-1.eks.amazonaws.com"}` |
| `cluster_certificate_authority_data` | Mapa de datos de los certificados de autoridad de los clusters EKS | `{"main" = "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0t..."}` |
| `cluster_security_group_ids` | Mapa de IDs de los grupos de seguridad adjuntos a los clusters EKS | `{"main" = "sg-0123456789abcdef0"}` |
| `cluster_versions` | Mapa de versiones de Kubernetes de los clusters EKS | `{"main" = "1.28"}` |
| `cluster_oidc_issuer_urls` | Mapa de URLs de los emisores OIDC de los clusters EKS | `{"main" = "https://oidc.eks.us-east-1.amazonaws.com/id/1234567890ABCDEF"}` |
| `oidc_provider_arns` | Mapa de ARNs de los proveedores OIDC | `{"main" = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/1234567890ABCDEF"}` |

## Ejemplos de uso

### Ejemplo básico

```hcl
module "eks_cluster" {
  source = "../../modules/eks-cluster"
  
  providers = {
    aws.project = aws.principal
  }
  
  client      = "pragma"
  project     = "demo"
  environment = "dev"
  
  eks_config = {
    "main" = {
      kubernetes_version      = "1.28"
      vpc_id                  = "vpc-12345678"
      subnet_ids              = ["subnet-1", "subnet-2", "subnet-3"]
      cluster_role_arn        = "arn:aws:iam::123456789012:role/EksClusterRole"
      cluster_security_group_ids = ["sg-12345678"]
      
      # Configuración de cifrado obligatoria
      encryption_config = [{
        provider_key_arn = "arn:aws:kms:us-east-1:123456789012:key/abcd1234-ab12-cd34-ef56-abcdef123456"
        resources        = ["secrets"]
      }]
    }
  }
}
```

### Ejemplo con configuración avanzada

```hcl
module "eks_cluster" {
  source = "../../modules/eks-cluster"
  
  providers = {
    aws.project = aws.principal
  }
  
  client      = "pragma"
  project     = "demo"
  environment = "dev"
  
  eks_config = {
    "main" = {
      kubernetes_version      = "1.28"
      vpc_id                  = "vpc-12345678"
      subnet_ids              = ["subnet-1", "subnet-2", "subnet-3"]
      cluster_role_arn        = "arn:aws:iam::123456789012:role/EksClusterRole"
      cluster_security_group_ids = ["sg-12345678"]
      
      # Configuración de acceso al endpoint
      endpoint_private_access = true
      endpoint_public_access  = true
      public_access_cidrs     = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
      
      # Configuración de red de Kubernetes
      ip_family         = "ipv4"
      service_ipv4_cidr = "172.20.0.0/16"
      
      # Configuración avanzada de acceso
      access_config = {
        authentication_mode = "API_AND_CONFIG_MAP"
        bootstrap_cluster_creator_admin_permissions = true
      }
      
      # Configuración de cifrado
      encryption_config = [{
        provider_key_arn = "arn:aws:kms:us-east-1:123456789012:key/abcd1234-ab12-cd34-ef56-abcdef123456"
        resources        = ["secrets"]
      }]
      
      # Configuración de logs
      create_cloudwatch_log_group            = true
      cloudwatch_log_group_retention_in_days = 30
      cluster_enabled_log_types              = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
      
      # Timeouts personalizados
      timeouts = {
        create = 45
        update = 60
        delete = 30
      }
      
      # Etiquetas adicionales
      additional_tags = {
        "kubernetes.io/cluster-name" = "pragma-demo-dev-eks-main"
        "environment" = "dev"
        "criticality" = "high"
      }
    }
  }
}
```

### Ejemplo con clave KMS por defecto

```hcl
data "aws_kms_key" "eks_secrets" {
  key_id = "alias/aws/eks"
}

module "eks_cluster" {
  source = "../../modules/eks-cluster"
  
  providers = {
    aws.project = aws.principal
  }
  
  client      = "pragma"
  project     = "demo"
  environment = "dev"
  
  eks_config = {
    "main" = {
      kubernetes_version      = "1.28"
      vpc_id                  = "vpc-12345678"
      subnet_ids              = ["subnet-1", "subnet-2", "subnet-3"]
      cluster_role_arn        = "arn:aws:iam::123456789012:role/EksClusterRole"
      cluster_security_group_ids = ["sg-12345678"]
      
      # Configuración de cifrado con clave por defecto
      encryption_config = [{
        provider_key_arn = data.aws_kms_key.eks_secrets.arn
        resources        = ["secrets"]
      }]
    }
  }
}
```

## Consideraciones de rendimiento

- **Creación del cluster**: La creación de un cluster EKS puede tardar entre 10-15 minutos.
- **Actualización de versión**: Las actualizaciones de versión pueden tardar hasta 45 minutos.
- **Logs de CloudWatch**: Habilitar todos los tipos de logs aumenta el volumen de datos enviados a CloudWatch, lo que puede afectar los costos.
- **Endpoint público vs privado**: El uso exclusivo de endpoint privado puede mejorar la seguridad pero requiere configuración adicional para acceder al cluster desde fuera de la VPC.
- **CIDR de servicios**: La elección del CIDR para servicios debe planificarse cuidadosamente para evitar conflictos con otras redes.
- **Número de subnets**: Incluir más de 2-3 subnets no mejora significativamente la disponibilidad pero puede aumentar la complejidad.
- **Versión de Kubernetes**: Las versiones más recientes pueden ofrecer mejoras de rendimiento y seguridad, pero es importante verificar la compatibilidad con los addons.
- **Grupos de seguridad**: Limitar el número de grupos de seguridad asociados al cluster para evitar alcanzar límites de reglas.
- **Proveedor OIDC**: La creación del proveedor OIDC es rápida pero puede haber un retraso en la propagación de la información.
- **Cifrado**: El cifrado de secretos tiene un impacto mínimo en el rendimiento pero añade una capa adicional de seguridad.

## Limitaciones conocidas

- **Cambios inmutables**: Algunos parámetros como `ip_family` y `service_ipv4_cidr` no pueden cambiarse después de la creación del cluster.
- **Versiones de Kubernetes**: No es posible saltar múltiples versiones mayores en una sola actualización.
- **Subnets**: Las subnets deben estar en al menos dos zonas de disponibilidad diferentes.
- **Cifrado**: Una vez habilitado el cifrado, no se puede deshabilitar.
- **Acceso al API server**: Cambiar la configuración de acceso al endpoint puede causar interrupciones temporales.
- **Compatibilidad de addons**: No todos los addons son compatibles con todas las versiones de Kubernetes.
- **Límites de servicio**: EKS tiene límites de servicio que pueden requerir solicitudes de aumento (por ejemplo, número máximo de clusters por cuenta).
- **Roles IAM**: El rol del cluster debe existir antes de crear el cluster y no puede cambiarse después.
- **Grupos de seguridad**: Los grupos de seguridad deben existir antes de crear el cluster.
- **Etiquetas de subnets**: Las subnets deben tener las etiquetas correctas para que EKS pueda utilizarlas correctamente.
- **Proveedor OIDC**: Solo se puede crear un proveedor OIDC por cluster.
- **Logs de CloudWatch**: No se pueden habilitar tipos de logs individuales después de la creación si inicialmente se configuraron como deshabilitados.
