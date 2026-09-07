###########################################
# PC-IAC-003 — Nomenclatura estándar
# PC-IAC-009 — Lógica de transformación en locals
# PC-IAC-012 — Único bloque locals, estructuras reutilizables
###########################################

locals {

  # ── Prefijo de gobernanza base ────────────────────────────────────────────
  # PC-IAC-003: patrón {client}-{project}-{environment}
  governance_prefix = "${var.client}-${var.project}-${var.environment}"

  # ── Nombres de clusters EKS ───────────────────────────────────────────────
  # PC-IAC-003: patrón {client}-{project}-{environment}-eks-{key}
  cluster_names = {
    for k, v in var.eks_config : k => {
      name = "${local.governance_prefix}-eks-${k}"
    }
  }

  # ── Nombre del Log Group de CloudWatch ───────────────────────────────────
  # Nombre estándar que EKS espera: /aws/eks/{cluster-name}/cluster
  cloudwatch_log_group_names = {
    for k, v in var.eks_config : k => "/aws/eks/${local.cluster_names[k].name}/cluster"
    if v.create_cloudwatch_log_group
  }

  # ── Derivación de bootstrap_self_managed_addons ───────────────────────────
  # Cuando Auto Mode está habilitado, bootstrap_self_managed_addons debe ser false.
  # Ref: Terraform docs nota crítica de aws_eks_cluster con compute_config.enabled.
  bootstrap_self_managed_addons = {
    for k, v in var.eks_config : k => (
      v.compute_config != null && v.compute_config.enabled == true ? false : true
    )
  }

}
