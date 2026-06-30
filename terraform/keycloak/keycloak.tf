locals {
  keycloak_hostname = "idp.${var.server_base_domain}"

  keycloak_features_enable = [
  ]
  keycloak_features_disable = [
  ]
}

resource "helm_release" "keycloak" {
  name      = "keycloak"
  namespace = kubernetes_namespace.keycloak.metadata[0].name

  repository = "https://codecentric.github.io/helm-charts"
  chart      = "keycloakx"
  version    = "7.2.0"

  timeout = 300

  set_sensitive = [
    {
      name  = "database.password"
      value = random_password.keycloak_db_password.result
    },
    {
      name  = "database.username"
      value = random_password.keycloak_db_username.result
    },
    {
      name  = "extraEnv"
      value = <<-EOF
        - name: KEYCLOAK_ADMIN
          value: ${random_password.keycloak_admin_username.result}
        - name: KEYCLOAK_ADMIN_PASSWORD
          value: ${random_password.keycloak_admin_password.result}
        %{if length(local.keycloak_features_enable) > 0}
        - name: KC_FEATURES
          value: "${join("\\,", local.keycloak_features_enable)}"
        %{endif}
        %{if length(local.keycloak_features_disable) > 0}
        - name: KC_FEATURES_DISABLED
          value: "${join("\\,", local.keycloak_features_disable)}"
        %{endif}
        - name: KC_HOSTNAME
          value: "${local.keycloak_hostname}"
        - name: KC_LOG_LEVEL
          value: "INFO"
      EOF
    },
  ]

  values = [
    yamlencode({
      args = ["start"]
      http = {
        relativePath = "/"
      }
    })
  ]

  set = [
    {
      name  = "database.vendor"
      value = "postgres"
    },
    {
      name  = "database.hostname"
      value = "${kubernetes_manifest.keycloak_db.manifest.metadata.name}-rw"
    },
    {
      name  = "database.port"
      value = "5432"
    },
    {
      name  = "database.database"
      value = kubernetes_manifest.keycloak_db.manifest.spec.bootstrap.initdb.database
    },
    {
      name  = "database.existingSecret"
      value = kubernetes_secret.db_credentials.metadata[0].name
    },
    {
      name  = "database.existingSecretKey"
      value = "password"
    },
    {
      name  = "proxy.mode"
      value = "xforwarded"
    },
    {
      name  = "ingress.enabled"
      value = "false"
    },
  ]
}

module "keycloak_ingress" {
  source = "../modules/ingress"

  name      = "keycloak"
  namespace = kubernetes_namespace.keycloak.metadata[0].name
  domain    = local.keycloak_hostname

  target_port = 80

  existing_service_name      = "${helm_release.keycloak.name}-keycloakx-http"
  existing_service_namespace = helm_release.keycloak.namespace
}
