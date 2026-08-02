resource "random_password" "keycloak_client_secret" {
  length  = 50
  numeric = true
  special = false
  upper   = true
}

resource "random_password" "loki_gateway_username" {
  length  = 16
  numeric = false
  special = false
  upper   = false
}

resource "random_password" "loki_gateway_password" {
  length  = 16
  numeric = true
  special = false
  upper   = true
}

resource "random_password" "loki_minio_root_username" {
  length  = 16
  numeric = false
  special = false
  upper   = false
}

resource "random_password" "loki_minio_root_password" {
  length  = 16
  numeric = true
  special = false
  upper   = true
}

resource "random_password" "grafana_db_username" {
  length  = 16
  numeric = false
  special = false
  upper   = false
}

resource "random_password" "grafana_db_password" {
  length  = 16
  numeric = true
  special = false
  upper   = true
}

resource "kubernetes_secret" "db_credentials" {
  metadata {
    name      = "db-credentials"
    namespace = kubernetes_namespace.grafana.metadata[0].name
  }

  data = {
    username = random_password.grafana_db_username.result
    password = random_password.grafana_db_password.result
  }
}
