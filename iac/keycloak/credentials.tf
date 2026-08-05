resource "random_password" "keycloak_admin_username" {
  length  = 16
  numeric = false
  special = false
  upper   = false
}

resource "random_password" "keycloak_admin_password" {
  length  = 16
  numeric = true
  special = false
  upper   = true
}

resource "random_password" "keycloak_db_username" {
  length  = 16
  numeric = false
  special = false
  upper   = false
}

resource "random_password" "keycloak_db_password" {
  length  = 16
  numeric = true
  special = false
  upper   = true
}

resource "kubernetes_secret" "db_credentials" {
  metadata {
    name      = "db-credentials"
    namespace = kubernetes_namespace.keycloak.metadata[0].name
  }

  data = {
    username = random_password.keycloak_db_username.result
    password = random_password.keycloak_db_password.result
  }
}
