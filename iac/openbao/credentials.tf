resource "random_password" "openbao_db_username" {
  length  = 16
  numeric = false
  special = false
  upper   = false
}

resource "random_password" "openbao_db_password" {
  length  = 16
  numeric = true
  special = false
  upper   = true
}

locals {
  # Literals rather than manifest references: the CNPG Cluster bootstraps from
  # this Secret (username/password), so referencing its manifest here would
  # cycle. Host is the cluster's deterministic rw service name.
  openbao_db_connection_url = "postgres://${random_password.openbao_db_username.result}:${random_password.openbao_db_password.result}@openbao-db-rw:5432/openbao"
}

# Consumed by CNPG (bootstrap.initdb.secret → username/password) and by the
# OpenBao server pod (connection-url → BAO_PG_CONNECTION_URL, injected via the
# chart's server.extraSecretEnvironmentVars).
resource "kubernetes_secret" "db_credentials" {
  metadata {
    name      = "db-credentials"
    namespace = kubernetes_namespace.openbao.metadata[0].name
  }

  data = {
    username       = random_password.openbao_db_username.result
    password       = random_password.openbao_db_password.result
    connection-url = local.openbao_db_connection_url
  }
}
