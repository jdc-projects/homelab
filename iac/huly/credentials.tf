# Keycloak OIDC client secret - consumed by the huly account service.
resource "random_password" "keycloak_client_secret" {
  length  = 50
  numeric = true
  special = false
  upper   = true
}

# CNPG Postgres credentials for the huly database.
resource "random_password" "huly_db_username" {
  length  = 16
  numeric = false
  special = false
  upper   = false
}

resource "random_password" "huly_db_password" {
  length  = 32
  numeric = true
  special = false
  upper   = true
}

resource "kubernetes_secret" "db_credentials" {
  metadata {
    name      = "db-credentials"
    namespace = kubernetes_namespace.huly.metadata[0].name
  }

  data = {
    username = random_password.huly_db_username.result
    password = random_password.huly_db_password.result
  }
}

# RustFS root credentials - used to run the server and directly by Huly
# (single-tenant homelab; no separate readwrite app user).
resource "random_password" "rustfs_root_username" {
  length  = 16
  numeric = false
  special = false
  upper   = false
}

resource "random_password" "rustfs_root_password" {
  length  = 32
  numeric = true
  special = false
  upper   = true
}
