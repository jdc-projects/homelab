resource "random_password" "mariadb_root_password" {
  length  = 50
  numeric = true
  special = false
  upper   = true
}

resource "kubernetes_secret" "mariadb_root_password" {
  metadata {
    name      = "mariadb-root-password"
    namespace = kubernetes_namespace.erpnext.metadata[0].name
  }

  data = {
    password = random_password.mariadb_root_password.result
  }
}

resource "random_password" "erpnext_admin_password" {
  length  = 50
  numeric = true
  special = false
  upper   = true
}

resource "kubernetes_secret" "erpnext_admin_password" {
  metadata {
    name      = "erpnext-admin-password"
    namespace = kubernetes_namespace.erpnext.metadata[0].name
  }

  data = {
    password = random_password.erpnext_admin_password.result
  }
}

resource "random_password" "mariadb_metrics_password" {
  length  = 50
  numeric = true
  special = false
  upper   = true
}

resource "kubernetes_secret" "mariadb_metrics_password" {
  metadata {
    name      = "mariadb-metrics-password"
    namespace = kubernetes_namespace.erpnext.metadata[0].name
  }

  data = {
    password = random_password.mariadb_metrics_password.result
  }
}

resource "random_password" "keycloak_client_secret" {
  length  = 50
  numeric = true
  special = false
  upper   = true
}

resource "kubernetes_secret" "keycloak_client_secret" {
  metadata {
    name      = "keycloak-client-secret"
    namespace = kubernetes_namespace.erpnext.metadata[0].name
  }

  data = {
    client-secret = random_password.keycloak_client_secret.result
  }
}
