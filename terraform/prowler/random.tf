resource "random_password" "prowler_db_superuser_username" {
  length  = 16
  numeric = false
  special = false
  upper   = false
}

resource "random_password" "prowler_db_superuser_password" {
  length  = 16
  numeric = true
  special = false
  upper   = true
}

resource "kubernetes_secret" "db_superuser_credentials" {
  metadata {
    name      = "db-superuser-credentials"
    namespace = kubernetes_namespace.prowler.metadata[0].name
  }

  data = {
    username = random_password.prowler_db_superuser_username.result
    password = random_password.prowler_db_superuser_password.result
  }
}

resource "random_password" "prowler_db_username" {
  length  = 16
  numeric = false
  special = false
  upper   = false
}

resource "random_password" "prowler_db_password" {
  length  = 16
  numeric = true
  special = false
  upper   = true
}

resource "kubernetes_secret" "db_credentials" {
  metadata {
    name      = "db-credentials"
    namespace = kubernetes_namespace.prowler.metadata[0].name
  }

  data = {
    username = random_password.prowler_db_username.result
    password = random_password.prowler_db_password.result
  }
}

resource "random_bytes" "prowler_auth_secret" {
  length = 32
}

resource "tls_private_key" "prowler_token_signing_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "random_bytes" "prowler_secrets_encryption_key" {
  length = 32
}

# oE/ltOhp/n1TdbHjVmzcjDPLcLA41CVI/4Rk+UB5ESc=
# N/c6mnaS5+SWq81+819OrzQZlmx1Vxtp/orjttJSmw8=

# Oi}SuVl܌3p8%Hd@y'
# 7:v䖫~_N4luWiR
