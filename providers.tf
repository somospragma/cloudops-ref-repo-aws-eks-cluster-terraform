###########################################
# PC-IAC-005 — Providers en Módulos de Referencia
#
# El provider se INYECTA desde el Root IaC mediante el alias aws.project.
# Este archivo solo declara la referencia al alias consumidor.
# La configuración real (region, assume_role, default_tags) se declara
# en el providers.tf del Root IaC (sample/ o proyecto raíz).
###########################################

# No se declara un bloque provider "aws" aquí.
# La declaración de configuration_aliases está en versions.tf (PC-IAC-006).
# Cada recurso en main.tf usa: provider = aws.project
