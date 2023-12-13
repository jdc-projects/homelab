resource "random_password" "harbor_db_username" {
  length  = 16
  numeric = false
  special = false
  upper   = false
}

resource "random_password" "harbor_db_password" {
  length  = 16
  numeric = true
  special = false
  upper   = true
}

resource "kubernetes_secret" "db_credentials" {
  metadata {
    name      = "db-credentials"
    namespace = kubernetes_namespace.harbor.metadata[0].name
  }

  data = {
    username = random_password.harbor_db_username.result
    password = random_password.harbor_db_password.result
  }
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

resource "random_password" "harbor_admin_password" {
  length  = 16
  numeric = true
  special = false
  upper   = true
}

resource "random_password" "harbor_secret_key" {
  length  = 16
  numeric = true
  special = false
  upper   = true
}

resource "random_password" "harbor_core_secret" {
  length  = 16
  numeric = true
  special = false
  upper   = true
}

resource "random_password" "harbor_jobservice_secret" {
  length  = 16
  numeric = true
  special = false
  upper   = true
}

resource "random_password" "harbor_registry_secret" {
  length  = 16
  numeric = true
  special = false
  upper   = true
}
