############################################################################
# Local Transformations - PC-IAC-026
############################################################################

# Patrón de Transformación: terraform.tfvars → data.tf → locals.tf → main.tf

locals {
  # Transformación de eks_config con inyección de IDs dinámicos
  eks_config_with_resources = {
    for key, config in var.eks_config :
    key => merge(config, {
      # Inyectar VPC ID desde data source si está vacío
      vpc_id = length(config.vpc_id) > 0 ? config.vpc_id : data.aws_vpc.selected.id
      
      # Inyectar Subnet IDs desde data source si está vacío
      subnet_ids = length(config.subnet_ids) > 0 ? config.subnet_ids : data.aws_subnets.private.ids
      
      # Inyectar Cluster Role ARN desde data source si está vacío
      cluster_role_arn = length(config.cluster_role_arn) > 0 ? config.cluster_role_arn : data.aws_iam_role.eks_cluster.arn
      
      # Inyectar KMS Key ARN en encryption_config si está vacío
      encryption_config = [
        for enc in config.encryption_config : {
          provider_key_arn = length(enc.provider_key_arn) > 0 ? enc.provider_key_arn : data.aws_kms_key.eks_secrets.arn
          resources        = enc.resources
        }
      ]
      
      # Inyectar Node Role ARN en compute_config si Auto Mode está habilitado
      compute_config = config.compute_config != null && config.compute_config.enabled ? {
        enabled       = config.compute_config.enabled
        node_pools    = config.compute_config.node_pools
        node_role_arn = config.compute_config.node_role_arn != null && length(config.compute_config.node_role_arn) > 0 ? config.compute_config.node_role_arn : data.aws_iam_role.eks_node.arn
      } : null
    })
  }
}
