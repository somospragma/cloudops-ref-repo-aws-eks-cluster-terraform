###########################################
# PC-IAC-011 — Data Sources (exclusivos del Root/sample)
# PC-IAC-026 — Data sources inyectan IDs dinámicos en locals.tf
#
# Convención de naming para filtros por tag Name:
#   {client}-{project}-{environment}-{tipo}
###########################################

# ── VPC ───────────────────────────────────────────────────────────────────
data "aws_vpc" "selected" {
  filter {
    name   = "tag:Name"
    values = ["${var.client}-${var.project}-${var.environment}-vpc"]
  }
}

# ── Subnets Privadas ───────────────────────────────────────────────────────
# EKS recomienda subnets privadas para el data plane y el control plane
data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }

  filter {
    name   = "tag:Name"
    values = ["${var.client}-${var.project}-${var.environment}-subnet-private-*"]
  }
}

# ── IAM Role del Cluster EKS ───────────────────────────────────────────────
data "aws_iam_role" "eks_cluster_role" {
  name = "${var.client}-${var.project}-${var.environment}-eks-cluster-role"
}

# ── KMS Key para cifrado de secrets ───────────────────────────────────────
data "aws_kms_key" "eks_secrets" {
  key_id = "alias/${var.client}-${var.project}-${var.environment}-eks-secrets"
}
