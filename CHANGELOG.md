# Changelog

Todos los cambios notables en este módulo serán documentados en este archivo.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/),
y este proyecto adhiere a [Semantic Versioning](https://semver.org/lang/es/).

## [2.1.0] - 2024-12-19

### Added
- ✨ Soporte completo para **EKS Auto Mode** via `compute_config`
- ✨ Configuración de `node_pools` y `node_role_arn` para Auto Mode
- 📄 Archivo `data.tf` para cumplir con PC-IAC-001
- 📄 Este archivo `CHANGELOG.md` para cumplir con PC-IAC-001
- 📁 Estructura completa de `sample/` con 8 archivos obligatorios (PC-IAC-026)

### Changed
- 📝 Actualizado `variables.tf` con `compute_config` opcional
- 📝 Actualizado `main.tf` con bloque dinámico `compute_config`
- 📝 Actualizado `README.md` con documentación de Auto Mode

### Fixed
- 🐛 Cumplimiento 100% con PC-IAC-001 (18 archivos obligatorios)
- 🐛 Cumplimiento 100% con PC-IAC-026 (sample funcional completo)

## [2.0.1] - 2024-12-19

### Added
- 📝 Documentación del sistema de etiquetado de dos capas (PC-IAC-004)
- 📝 Sección "🏷️ Sistema de Etiquetado (Tagging)" en README.md

### Fixed
- 🐛 Variable `region` faltante en `sample/variables.tf` (PC-IAC-026)
- 🐛 Error en `sample/providers.tf` que usaba `var.region` sin definir

## [2.0.0] - 2024-12-15

### Added
- ✨ Módulo inicial de EKS Cluster
- ✨ Soporte para múltiples clusters via `for_each`
- ✨ Configuración de cifrado con KMS
- ✨ Logs de CloudWatch configurables
- ✨ Proveedor OIDC automático
- ✨ Configuración de acceso al endpoint (público/privado)
- ✨ Configuración de red de Kubernetes (IPv4/IPv6)
- ✨ Timeouts personalizables
- ✨ Sistema de etiquetado de dos capas

### Security
- 🔒 Cifrado obligatorio de secrets con KMS
- 🔒 Endpoint privado habilitado por defecto
- 🔒 Logs del control plane habilitados por defecto
- 🔒 OIDC provider para IRSA (IAM Roles for Service Accounts)

### Documentation
- 📝 README.md completo con ejemplos
- 📝 Documentación de inputs y outputs
- 📝 Consideraciones de rendimiento
- 📝 Limitaciones conocidas
