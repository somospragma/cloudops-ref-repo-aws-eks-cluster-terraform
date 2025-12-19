############################################################################
# Data Sources - PC-IAC-026
############################################################################

# Obtener información de la VPC
data "aws_vpc" "selected" {
  provider = aws.principal
  
  filter {
    name   = "tag:Name"
    values = ["${var.client}-networking-${var.environment}-vpc"]
  }
}

# Obtener subnets privadas para el cluster EKS
data "aws_subnets" "private" {
  provider = aws.principal
  
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }

  filter {
    name   = "tag:Name"
    values = ["${var.client}-networking-${var.environment}-subnet-private-*"]
  }
}

# Obtener rol IAM del cluster EKS
data "aws_iam_role" "eks_cluster" {
  provider = aws.principal
  name     = "${var.client}-${var.project}-${var.environment}-cluster-role"
}

# Obtener rol IAM de los nodos EKS (para Auto Mode)
data "aws_iam_role" "eks_node" {
  provider = aws.principal
  name     = "${var.client}-${var.project}-${var.environment}-node-role"
}

# Obtener clave KMS para cifrado de secrets
data "aws_kms_key" "eks_secrets" {
  provider = aws.principal
  key_id   = "alias/${var.client}-${var.project}-${var.environment}-eks"
}

# Obtener información de la cuenta AWS actual
data "aws_caller_identity" "current" {
  provider = aws.principal
}

# Obtener región actual
data "aws_region" "current" {
  provider = aws.principal
}
