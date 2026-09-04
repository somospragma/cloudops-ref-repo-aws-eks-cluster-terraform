###########################################
# PC-IAC-009 — Inyección de valores dinámicos desde data sources
# PC-IAC-021 — Centralización de configuración en locals
# PC-IAC-025 — Nomenclatura de gobernanza procesada aquí
# PC-IAC-026 — Patrón de Transformación: tfvars → locals → main
#
# Este archivo transforma var.eks_config inyectando los IDs dinámicos
# obtenidos de los data sources en data.tf.
# sample/main.tf SOLO consume local.eks_config_transformed.
###########################################

locals {

  # ── Prefijo de gobernanza ────────────────────────────────────────────────
  # PC-IAC-025: nomenclatura construida en el Root
  governance_prefix = "${var.client}-${var.project}-${var.environment}"

  # ── Transformación del eks_config ────────────────────────────────────────
  # PC-IAC-026: inyectar IDs dinámicos sobre la configuración base de tfvars
  # Campos vacíos ("", []) se reemplazan con valores de data sources.
  eks_config_transformed = {
    for key, config in var.eks_config : key => merge(config, {

      # Inyectar cluster_role_arn desde data source si viene vacío
      cluster_role_arn = length(config.cluster_role_arn) > 0 ? config.cluster_role_arn : data.aws_iam_role.eks_cluster_role.arn

      # Inyectar subnet_ids desde data source si viene vacío
      subnet_ids = length(config.subnet_ids) > 0 ? config.subnet_ids : data.aws_subnets.private.ids

      # Inyectar configuración de cifrado KMS
      # Se construye aquí para usar el ARN dinámico de la key
      encryption_config = [{
        provider_key_arn = data.aws_kms_key.eks_secrets.arn
        resources        = ["secrets"]
      }]
    })
  }

}
