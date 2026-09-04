# Sample — Cluster EKS Estándar

Ejemplo funcional que demuestra el uso del módulo `cloudops-ref-repo-aws-eks-cluster-terraform`
siguiendo el patrón de transformación PC-IAC-026.

---

## Patrón de Transformación (PC-IAC-026)

```
terraform.tfvars          → Configuración base (sin IDs hardcodeados)
     ↓
variables.tf              → Tipos y validaciones
     ↓
data.tf                   → Data sources para IDs dinámicos (VPC, Subnets, IAM, KMS)
     ↓
locals.tf                 → Inyección de IDs en el mapa de configuración
     ↓
main.tf                   → Invoca el módulo con local.eks_config_transformed
```

---

## Pre-requisitos

Antes de ejecutar este ejemplo, deben existir en la cuenta AWS:

| Recurso | Nombre esperado (tag Name) |
|---|---|
| VPC | `{client}-{project}-{env}-vpc` |
| Subnets privadas | `{client}-{project}-{env}-subnet-private-*` |
| IAM Role del cluster | `{client}-{project}-{env}-eks-cluster-role` |
| KMS Key alias | `alias/{client}-{project}-{env}-eks-secrets` |

---

## Configuración

1. Actualizar `terraform.tfvars` con los valores de tu entorno:

```hcl
client      = "pragma"
project     = "eks-platform"
environment = "dev"
region      = "us-east-1"
aws_profile = "mi-perfil-aws"
```

2. (Opcional) Descomentar el bloque `backend "s3"` en `providers.tf` y configurar el bucket de estado.

3. (Opcional) Descomentar `assume_role` en `providers.tf` para pipelines CI/CD.

---

## Ejecución

```bash
# Inicializar
terraform init

# Planificar
terraform plan

# Aplicar
terraform apply

# Ver outputs
terraform output cluster_names
terraform output cluster_endpoints
terraform output oidc_provider_arns
```

---

## Outputs Esperados

Tras un despliegue exitoso:

- `cluster_names` — nombre del cluster: `pragma-eks-platform-dev-eks-main`
- `cluster_endpoints` — endpoint HTTPS del API server
- `cluster_statuses` — `ACTIVE`
- `oidc_provider_arns` — ARN del OIDC Provider para configurar IRSA en módulos de addons
- `cloudwatch_log_group_names` — `/aws/eks/pragma-eks-platform-dev-eks-main/cluster`

---

## Módulos Siguientes

Una vez desplegado el cluster, continuar con:

1. **eks-nodegroups** o **eks-fargate** — para el compute
2. **eks-addons** — para CoreDNS, VPC CNI, kube-proxy
