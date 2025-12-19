# Sample - EKS Cluster Module

Este directorio contiene ejemplos funcionales de uso del módulo EKS Cluster.

## 📋 Prerequisitos

Antes de ejecutar este sample, asegúrate de tener:

1. **VPC y Networking**: Debe existir una VPC con el nombre `{client}-networking-{environment}-vpc`
2. **Subnets privadas**: Deben existir subnets con el patrón `{client}-networking-{environment}-subnet-private-*`
3. **IAM Roles**:
   - Rol del cluster: `{client}-{project}-{environment}-cluster-role`
   - Rol de nodos: `{client}-{project}-{environment}-node-role` (solo si usas Auto Mode)
4. **KMS Key**: Debe existir una clave KMS con alias `{client}-{project}-{environment}-eks`

## 🚀 Uso

### 1. Configurar variables

Edita `terraform.tfvars` con tus valores:

```hcl
client      = "pragma"
project     = "demo"
environment = "dev"
region      = "us-east-1"
```

### 2. Inicializar Terraform

```bash
terraform init
```

### 3. Validar configuración

```bash
terraform validate
```

### 4. Planificar cambios

```bash
terraform plan
```

### 5. Aplicar cambios

```bash
terraform apply
```

## 📁 Estructura de archivos

Este sample sigue el patrón PC-IAC-026:

```
sample/
├── main.tf           # Invocación del módulo
├── variables.tf      # Definición de variables
├── providers.tf      # Configuración de providers
├── data.tf           # Data sources para recursos existentes
├── locals.tf         # Transformaciones de datos
├── outputs.tf        # Outputs del módulo
├── terraform.tfvars  # Valores de variables
└── README.md         # Esta documentación
```

## 🔄 Patrón de Transformación (PC-IAC-026)

El flujo de datos sigue este patrón:

```
terraform.tfvars → variables.tf → data.tf → locals.tf → main.tf
```

### Ejemplo:

1. **terraform.tfvars**: Define `vpc_id = ""`
2. **data.tf**: Obtiene VPC por nombre: `data.aws_vpc.selected`
3. **locals.tf**: Inyecta el ID: `vpc_id = data.aws_vpc.selected.id`
4. **main.tf**: Consume la configuración transformada

## 🎯 Ejemplos incluidos

### Ejemplo básico (terraform.tfvars)

Cluster EKS básico sin Auto Mode:

```hcl
eks_config = {
  "main" = {
    kubernetes_version = "1.31"
    vpc_id             = ""  # Se obtiene automáticamente
    subnet_ids         = []  # Se obtienen automáticamente
    cluster_role_arn   = ""  # Se obtiene automáticamente
    
    encryption_config = [{
      provider_key_arn = ""  # Se obtiene automáticamente
      resources        = ["secrets"]
    }]
  }
}
```

### Ejemplo con Auto Mode (01-basic-cluster/)

Cluster EKS con Auto Mode habilitado:

```hcl
eks_config = {
  "main" = {
    kubernetes_version = "1.31"
    
    # Auto Mode habilitado
    compute_config = {
      enabled       = true
      node_pools    = ["general-purpose", "system"]
      node_role_arn = ""  # Se obtiene automáticamente
    }
    
    encryption_config = [{
      provider_key_arn = ""
      resources        = ["secrets"]
    }]
  }
}
```

## 🏷️ Sistema de Etiquetado

Este sample implementa el sistema de dos capas (PC-IAC-004):

### Capa 1: Tags Transversales (default_tags)

Configurados en `providers.tf`:

```hcl
default_tags {
  tags = {
    client      = var.client
    project     = var.project
    environment = var.environment
    provisioned = "terraform"
  }
}
```

### Capa 2: Tags Específicos (additional_tags)

Configurados en `terraform.tfvars`:

```hcl
additional_tags = {
  "kubernetes.io/cluster-name" = "pragma-demo-dev-eks-main"
  "ManagedBy"                  = "Terraform"
  "AutoMode"                   = "enabled"
}
```

## 🔐 Seguridad

El sample implementa:

- ✅ Cifrado de secrets con KMS
- ✅ Endpoint privado habilitado por defecto
- ✅ Logs del control plane habilitados
- ✅ OIDC provider para IRSA
- ✅ Roles IAM con menor privilegio

## 📚 Referencias

- [Módulo EKS Cluster](../)
- [Documentación de EKS Auto Mode](https://docs.aws.amazon.com/eks/latest/userguide/auto-mode.html)
- [Reglas PC-IAC](../../../rules/cloudops-ref-repo-iac-rules-terraform/)
