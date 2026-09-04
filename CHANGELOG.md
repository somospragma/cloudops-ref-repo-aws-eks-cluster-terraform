# Changelog

Todos los cambios notables de este módulo se documentan en este archivo.

El formato sigue [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
y este proyecto adhiere a [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Added
- Soporte completo para EKS Auto Mode (`compute_config`, `storage_config`, `elastic_load_balancing`)
- Validación de consistencia Auto Mode: los tres flags deben estar alineados
- Soporte para `deletion_protection` (protección de eliminación accidental)
- Soporte para `upgrade_policy` (EXTENDED / STANDARD support)
- Soporte para `control_plane_scaling_config` (tiers de control plane)
- Soporte para `zonal_shift_config` (ARC Zonal Shift)
- Soporte para `force_update_version`
- Soporte para `kube_api_server_config` (event_ttl, service_node_port_range)
- Soporte para `kube_controller_manager_config` (HPA sync period, Pod GC threshold)
- Soporte para `kube_scheduler_config` (scoring strategy)
- Soporte para `remote_network_config` (EKS Hybrid Nodes)
- Soporte para `control_plane_egress_mode`
- Output `cluster_platform_versions` (versión de plataforma EKS)
- Output `cluster_statuses` (estado del cluster)
- Output `cluster_created_at` (timestamp de creación)
- Output `cluster_vpc_ids` (VPC asociada al cluster)
- Output `oidc_provider_urls` (URL sin prefijo para trust policies)
- Output `cloudwatch_log_group_names` y `cloudwatch_log_group_arns`
- `versions.tf` separado con `configuration_aliases = [aws.project]` (PC-IAC-005/006)
- `locals.tf` con `governance_prefix` y `bootstrap_self_managed_addons` derivado automáticamente
- Tags con `merge(Name, additional_tags)` en todos los recursos (PC-IAC-004)
- Directorio `sample/` con patrón de transformación PC-IAC-026
- Cumplimiento de 26 reglas PC-IAC Pragma

### Changed
- `providers.tf` ahora es un archivo de documentación (sin bloque terraform)
- `variables.tf` migrado a `map(object)` con `optional()` para todos los campos
- `main.tf` refactorizado con bloques `dynamic` para toda configuración opcional
- Nomenclatura de recursos sigue el patrón `{client}-{project}-{env}-eks-{key}`

### Fixed
- Tags en `aws_eks_cluster` ahora incluyen `Name` explícito (PC-IAC-004)
- `bootstrap_self_managed_addons` se deriva automáticamente según `compute_config.enabled`

---

## [1.0.0] - TBD

### Added
- Versión inicial estable del módulo
- Soporte para `aws_eks_cluster`, `aws_cloudwatch_log_group`, `aws_iam_openid_connect_provider`
