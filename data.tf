###########################################
# PC-IAC-011 — Data Sources
#
# Los Data Sources que consultan recursos existentes en la cuenta AWS
# (VPCs, Subnets, KMS Keys, IAM Roles, etc.) deben declararse en el
# Root IaC (sample/data.tf o proyecto raíz), NO en este módulo.
#
# Los resultados se inyectan como variables de entrada (var.*).
#
# Excepción permitida: data sources genéricos que no consultan
# recursos específicos de la cuenta (ej: data.aws_region.current,
# data.tls_certificate — este último se declara en main.tf porque
# depende del output del cluster recién creado).
###########################################
