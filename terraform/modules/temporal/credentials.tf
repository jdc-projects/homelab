resource "random_password" "temporal_db_password" {
  length  = 32
  special = false
}

resource "kubernetes_secret" "temporal_db_credentials" {
  metadata {
    name      = "${var.name_prefix}-db-credentials"
    namespace = var.namespace
  }

  data = {
    username = "temporal"
    password = random_password.temporal_db_password.result
  }
}

resource "kubernetes_secret" "temporal_secrets" {
  metadata {
    name      = "${var.name_prefix}-secrets"
    namespace = var.namespace
  }

  data = {
    POSTGRES_PWD = random_password.temporal_db_password.result
  }
}
