locals {
  postgres_operator_ui_domain = "postgres.${var.server_base_domain}"
}

resource "helm_release" "postgres_operator_ui" {
  name      = "postgres-operator-ui"
  namespace = kubernetes_namespace.postgres_operator.metadata[0].name

  repository = "https://opensource.zalando.com/postgres-operator/charts/postgres-operator-ui"
  chart      = "postgres-operator-ui"
  version    = "1.10.1"

  timeout = 300

  set {
    name  = "envs.appUrl"
    value = "https://${local.postgres_operator_ui_domain}"
  }
  set {
    name  = "envs.operatorApiUrl"
    value = "http://${helm_release.postgres_operator.name}:8080"
  }
  set {
    name  = "envs.targetNamespace"
    value = kubernetes_namespace.postgres_operator.metadata[0].name
  }

  set {
    name  = "extraEnvs[0].name"
    value = "READ_ONLY_MODE"
  }
  set {
    name  = "extraEnvs[0].value"
    value = "true"
  }
}

module "postgres_operator_ui_ingress" {
  source = "../modules/auth-ingress"

  server_base_domain = var.server_base_domain
  namespace          = kubernetes_namespace.postgres_operator.metadata[0].name
  service_name       = helm_release.postgres_operator_ui.name
  service_port       = 80
  url_subdomain      = "postgres"
}
