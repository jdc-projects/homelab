resource "random_password" "appflowy_db_username" {
  length  = 16
  numeric = false
  special = false
  upper   = false
}

resource "random_password" "appflowy_db_password" {
  length  = 16
  numeric = true
  special = false
  upper   = true
}

resource "kubernetes_secret" "db_credentials" {
  metadata {
    name      = "db-credentials"
    namespace = kubernetes_namespace.appflowy.metadata[0].name
  }

  data = {
    username = random_password.appflowy_db_username.result
    password = random_password.appflowy_db_password.result
  }
}

resource "random_password" "appflowy_redis_password" {
  length  = 16
  numeric = true
  special = false
  upper   = true
}

resource "random_password" "keycloak_client_secret" {
  length  = 50
  numeric = true
  special = false
  upper   = true
}

resource "random_password" "minio_root_username" {
  length  = 16
  numeric = false
  special = false
  upper   = false
}

resource "random_password" "minio_root_password" {
  length  = 16
  numeric = true
  special = false
  upper   = true
}

resource "random_password" "minio_access_key" {
  length  = 16
  numeric = false
  special = false
  upper   = false
}

resource "random_password" "minio_secret_key" {
  length  = 16
  numeric = true
  special = false
  upper   = true
}
