# cloudops-ref-repo-aws-eks-cluster-terraform

Módulo de Referencia Terraform para la creación de clusters **Amazon EKS** siguiendo las 26 reglas de gobernanza PC-IAC de Pragma y las mejores prácticas del AWS Well-Architected Framework.

---

## Descripción

Este módulo tiene **responsabilidad única** (PC-IAC-023): crea y gestiona exclusivamente los recursos del cluster EKS y su infraestructura de plano de control:

| Recurso | Descripción |
|---|---|
| `aws_eks_cluster` | El cluster EKS con todas sus configuraciones |
| `aws_cloudwatch_log_group` | Log Group para los logs del control plane |
| `aws_iam_openid_connect_provider` | OIDC Provider para IRSA y Pod Identity |

**No crea:** IAM Roles, Security Groups, VPC, Subnets, Node Groups, Fargate Profiles ni Addons. Esos recursos son responsabilidad de los módulos correspondientes o del Root IaC.

---

## Modos de Despliegue Soportados

### Cluster estándar (Node Groups / Fargate)
Cluster EKS con acceso al API server, logging habilitado y OIDC configurado. El compute lo gestionan los módulos `eks-nodegroups` o `eks-fargate`.

### Cluster con Auto Mode
EKS Auto Mode delega la gestión completa del data plane a AWS (Karpenter integrado, AMI inmutable Bottlerocket, vida máxima de nodo 21 días). Requiere habilitar `compute_config`, `elastic_load_balancing_enabled` y `block_storage_enabled` **todos en true** simultáneamente.

> **Nota crítica:** `bootstrap_self_managed_addons` se deriva automáticamente en `locals.tf` — es `false` cuando Auto Mode está activo y `true` en caso contrario. No es necesario configurarlo manualmente.

---

## Requisitos Previos

El módulo **recibe** estos recursos como variables de entrada (no los crea):

- **VPC** con subnets en mínimo 2 zonas de disponibilidad
- **IAM Role** para el cluster con las políticas necesarias:
  - `AmazonEKSClusterPolicy` (siempre)
  - `AmazonEKSComputePolicy`, `AmazonEKSBlockStoragePolicy`, `AmazonEKSLoadBalancingPolicy`, `AmazonEKSNetworkingPolicy` (solo Auto Mode)
- **IAM Role** para nodos (solo Auto Mode): `AmazonEKSWorkerNodeMinimalPolicy` + `AmazonEC2ContainerRegistryPullOnly`
- **KMS Key** (recomendado en producción) para cifrado de secrets

---

## Uso

```hcl
module "eks_cluster" {
  source = "git::https://github.com/somospragma/cloudops-ref-repo-aws-eks-cluster-terraform.git?ref=feature/init-module-eks-cluster"

  providers = {
    aws.project = aws.principal
  }

  client      = "pragma"
  project     = "eks-platform"
  environment = "dev"

  eks_config = {
    "main" = {
      kubernetes_version = "1.32"
      cluster_role_arn   = "arn:aws:iam::123456789012:role/pragma-eks-platform-dev-eks-cluster-role"
      subnet_ids         = ["subnet-aaa111", "subnet-bbb222", "subnet-ccc333"]

      # Acceso privado por defecto (PC-IAC-020)
      endpoint_private_access = true
      endpoint_public_access  = false

      # Cifrado de secrets con KMS (recomendado producción)
      encryption_config = [{
        provider_key_arn = "arn:aws:kms:us-east-1:123456789012:key/mrk-abc123"
        resources        = ["secrets"]
      }]

      # Autenticación moderna
      access_config = {
        authentication_mode                         = "API"
        bootstrap_cluster_creator_admin_permissions = true
      }

      # Upgrade policy
      upgrade_policy = {
        support_type = "EXTENDED"
      }

      additional_tags = {
        "team" = "platform"
      }
    }
  }
}
```

### Ejemplo con Auto Mode

```hcl
eks_config = {
  "main" = {
    kubernetes_version = "1.32"
    cluster_role_arn   = "arn:aws:iam::123456789012:role/pragma-eks-platform-dev-eks-cluster-role"
    subnet_ids         = ["subnet-aaa111", "subnet-bbb222"]

    # Auto Mode — los tres flags deben ser true simultáneamente
    compute_config = {
      enabled       = true
      node_pools    = ["general-purpose", "system"]
      node_role_arn = "arn:aws:iam::123456789012:role/pragma-eks-platform-dev-eks-node-role"
    }
    elastic_load_balancing_enabled = true
    block_storage_enabled          = true

    # Auto Mode requiere API o API_AND_CONFIG_MAP
    access_config = {
      authentication_mode = "API"
    }

    deletion_protection = true

    upgrade_policy = {
      support_type = "EXTENDED"
    }
  }
}
```

---

## Inputs

| Variable | Tipo | Requerido | Default | Descripción |
|---|---|---|---|---|
| `client` | `string` | Sí | — | Nombre del cliente (max 10 chars, solo [a-z0-9-]) |
| `project` | `string` | Sí | — | Nombre del proyecto (max 15 chars, solo [a-z0-9-]) |
| `environment` | `string` | Sí | — | Entorno: `dev`, `qa`, `pdn` |
| `eks_config` | `map(object)` | Sí | — | Mapa de configuraciones de clusters EKS |

### eks_config — Campos principales

| Campo | Tipo | Requerido | Default | Descripción |
|---|---|---|---|---|
| `kubernetes_version` | `string` | Sí | — | Versión de Kubernetes. Ej: `"1.32"` |
| `cluster_role_arn` | `string` | Sí | — | ARN del IAM Role del control plane |
| `subnet_ids` | `list(string)` | Sí | — | Mínimo 2 subnets en AZs distintas |
| `security_group_ids` | `list(string)` | No | `[]` | SGs adicionales para ENIs del control plane |
| `endpoint_private_access` | `bool` | No | `true` | Habilita endpoint privado |
| `endpoint_public_access` | `bool` | No | `false` | Habilita endpoint público |
| `public_access_cidrs` | `list(string)` | No | `["0.0.0.0/0"]` | CIDRs para endpoint público |
| `control_plane_egress_mode` | `string` | No | `"AWS_MANAGED"` | `AWS_MANAGED` o `CUSTOMER_ROUTED` (inmutable) |
| `ip_family` | `string` | No | `"ipv4"` | `ipv4` o `ipv6` (inmutable) |
| `service_ipv4_cidr` | `string` | No | `null` | CIDR para servicios K8s (inmutable) |
| `elastic_load_balancing_enabled` | `bool` | No | `false` | ELB para Auto Mode (debe alinearse con compute_config) |
| `compute_config` | `object` | No | `null` | Configuración de Auto Mode |
| `compute_config.enabled` | `bool` | No | `false` | Habilita Auto Mode |
| `compute_config.node_pools` | `list(string)` | No | `["general-purpose","system"]` | Node pools de Auto Mode |
| `compute_config.node_role_arn` | `string` | Sí si Auto Mode | `null` | ARN del rol para nodos EC2 gestionados |
| `block_storage_enabled` | `bool` | No | `false` | EBS CSI para Auto Mode (debe alinearse) |
| `access_config` | `object` | No | `null` | Configuración de autenticación |
| `access_config.authentication_mode` | `string` | No | `"API"` | `API`, `API_AND_CONFIG_MAP`, `CONFIG_MAP` |
| `access_config.bootstrap_cluster_creator_admin_permissions` | `bool` | No | `true` | Admin para el creador |
| `encryption_config` | `list(object)` | No | `[]` | Cifrado KMS para secrets |
| `deletion_protection` | `bool` | No | `false` | Protege de eliminación accidental |
| `force_update_version` | `bool` | No | `false` | Fuerza upgrade ignorando readiness checks |
| `upgrade_policy.support_type` | `string` | No | `"EXTENDED"` | `EXTENDED` o `STANDARD` |
| `control_plane_scaling_config.tier` | `string` | No | `"standard"` | Tier del control plane |
| `zonal_shift_config.enabled` | `bool` | No | `false` | ARC Zonal Shift (no soportado en Auto Mode) |
| `kube_api_server_config` | `object` | No | `null` | Config del API server (event_ttl, node port range) |
| `kube_controller_manager_config` | `object` | No | `null` | Config del controller manager (HPA, Pod GC) |
| `kube_scheduler_config` | `object` | No | `null` | Config del scheduler (scoring strategy) |
| `remote_network_config` | `object` | No | `null` | Config de Hybrid Nodes |
| `create_cloudwatch_log_group` | `bool` | No | `true` | Crea Log Group en CloudWatch |
| `cloudwatch_log_group_retention_in_days` | `number` | No | `90` | Retención de logs (días) |
| `cluster_enabled_log_types` | `list(string)` | No | todos | Tipos de logs del control plane |
| `timeouts` | `object` | No | `null` | Timeouts de create/update/delete (minutos) |
| `additional_tags` | `map(string)` | No | `{}` | Tags adicionales para el cluster |

---

## Outputs

| Output | Descripción |
|---|---|
| `cluster_names` | Mapa de nombres de los clusters |
| `cluster_ids` | Mapa de IDs de los clusters |
| `cluster_arns` | Mapa de ARNs de los clusters |
| `cluster_endpoints` | Mapa de endpoints del API server |
| `cluster_certificate_authority_data` | Mapa de certificados CA (base64) para kubeconfig |
| `cluster_versions` | Mapa de versiones de Kubernetes |
| `cluster_platform_versions` | Mapa de versiones de plataforma EKS |
| `cluster_statuses` | Mapa de estados de los clusters |
| `cluster_created_at` | Mapa de timestamps de creación |
| `cluster_security_group_ids` | Mapa de SGs creados automáticamente por EKS |
| `cluster_vpc_ids` | Mapa de VPCs asociadas |
| `cluster_oidc_issuer_urls` | Mapa de URLs del emisor OIDC |
| `oidc_provider_arns` | Mapa de ARNs de los OIDC Providers de IAM |
| `oidc_provider_urls` | Mapa de URLs de los OIDC Providers (para trust policies) |
| `cloudwatch_log_group_names` | Mapa de nombres de los Log Groups |
| `cloudwatch_log_group_arns` | Mapa de ARNs de los Log Groups |

---

## Versiones Requeridas

| Componente | Versión Mínima |
|---|---|
| Terraform | `>= 1.5.0` |
| AWS Provider | `>= 5.75.0` |
| TLS Provider | `>= 4.0.0` |

> El provider AWS `>= 5.75.0` es necesario para soportar los nuevos argumentos del recurso `aws_eks_cluster`: `control_plane_scaling_config`, `kube_api_server_config`, `kube_controller_manager_config`, `kube_scheduler_config`, `deletion_protection`, `zonal_shift_config` y `upgrade_policy`.

---

## Nomenclatura de Recursos

El módulo genera los nombres siguiendo el patrón estándar Pragma (PC-IAC-003):

| Recurso | Patrón de Nombre |
|---|---|
| EKS Cluster | `{client}-{project}-{environment}-eks-{key}` |
| CloudWatch Log Group | `/aws/eks/{client}-{project}-{environment}-eks-{key}/cluster` |
| OIDC Provider | `{client}-{project}-{environment}-eks-{key}-oidc` (tag Name) |

---

## Cumplimiento PC-IAC

| Regla | ID | Implementación |
|---|---|---|
| Estructura de módulo | PC-IAC-001 | 10 archivos raíz + directorio sample/ |
| Variables tipadas y validadas | PC-IAC-002 | `map(object)` con `optional()` y bloques `validation` |
| Nomenclatura estándar | PC-IAC-003 | `{client}-{project}-{env}-eks-{key}` en `locals.tf` |
| Etiquetas (Tagging) | PC-IAC-004 | `merge(Name, additional_tags)` en todos los recursos |
| Provider alias | PC-IAC-005 | `provider = aws.project` en todos los recursos |
| Versiones fijadas | PC-IAC-006 | `versions.tf` con `configuration_aliases` |
| Outputs granulares | PC-IAC-007 | Solo IDs/ARNs, no objetos completos |
| Data sources en Root | PC-IAC-011 | Prohibidos en módulo, solo `data.tls_certificate` interno |
| Lógica en locals | PC-IAC-012 | `governance_prefix`, nombres, `bootstrap_self_managed_addons` |
| Bloques dinámicos | PC-IAC-014 | `dynamic` para toda configuración opcional |
| Hardenizado seguridad | PC-IAC-020 | `deletion_protection`, `encryption_config`, logs completos, endpoint privado por defecto |
| Responsabilidad única | PC-IAC-023 | Solo cluster EKS, OIDC y CW Logs. Sin IAM, SG, VPC, Addons |
| Patrón sample/ | PC-IAC-026 | `tfvars → locals.tf → main.tf` con data sources para IDs dinámicos |

---

## Decisiones de Diseño

### Auto Mode — validación de consistencia
El provider de Terraform exige que `compute_config.enabled`, `elastic_load_balancing_enabled` y `block_storage_enabled` estén **todos en `true` o todos en `false`**. El módulo implementa una validación que rechaza configuraciones inconsistentes en tiempo de plan.

### `bootstrap_self_managed_addons` derivado automáticamente
Este flag se calcula en `locals.tf` a partir de `compute_config.enabled`. No es necesario configurarlo manualmente — el módulo lo hace correctamente según el modo de despliegue.

### `data.tls_certificate` en `main.tf`
A pesar de que PC-IAC-011 prohíbe data sources en módulos de referencia, `data.tls_certificate` es una excepción justificada: este data source lee el certificado del endpoint OIDC que **el mismo módulo acaba de crear** (no consulta recursos preexistentes de la cuenta). Es un data source genérico que no viola el principio de separación de dominios.

### SGs en `vpc_config.security_group_ids`
Este campo acepta SGs adicionales para las ENIs del plano de control. **No es** el `cluster_security_group_id` que EKS crea automáticamente (ese es un atributo computed). Los SGs se reciben como variable, nunca se crean aquí (PC-IAC-023).

---

## Recursos Relacionados

- [Módulo eks-nodegroups](https://github.com/somospragma/cloudops-ref-repo-aws-eks-nodegroups-terraform)
- [Módulo eks-fargate](https://github.com/somospragma/cloudops-ref-repo-aws-eks-fargate-terraform)
- [Módulo eks-addons](https://github.com/somospragma/cloudops-ref-repo-aws-eks-addons-terraform)
- [Documentación oficial EKS Auto Mode](https://docs.aws.amazon.com/eks/latest/userguide/automode.html)
- [Terraform aws_eks_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_cluster)
