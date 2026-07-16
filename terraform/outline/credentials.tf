resource "random_id" "outline_secret_key" {
  byte_length = 32
}

resource "random_id" "outline_utils_secret" {
  byte_length = 32
}

resource "random_password" "outline_db_username" {
  length  = 16
  numeric = false
  special = false
  upper   = false
}

resource "random_password" "outline_db_password" {
  length  = 16
  numeric = true
  special = false
  upper   = true
}

resource "kubernetes_secret" "db_credentials" {
  metadata {
    name      = "db-credentials"
    namespace = kubernetes_namespace.outline.metadata[0].name
  }

  data = {
    username = random_password.outline_db_username.result
    password = random_password.outline_db_password.result
  }
}

resource "random_password" "keycloak_client_secret" {
  length  = 50
  numeric = true
  special = false
  upper   = true
}

# RustFS root credentials, used both to run the server and by Outline directly
# (single-tenant homelab -> no separate readwrite app user).
resource "random_password" "rustfs_root_username" {
  length  = 16
  numeric = false
  special = false
  upper   = false
}

resource "random_password" "rustfs_root_password" {
  length  = 16
  numeric = true
  special = false
  upper   = true
}
