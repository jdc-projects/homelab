resource "helm_release" "grafana" {
  name = "grafana"

  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  version    = "6.58.5"

  namespace = kubernetes_namespace.grafana.metadata[0].name

  timeout = 300

  set {
    name  = "ingress.enabled"
    value = "true"
  }
  set {
    name  = "ingress.hosts[0]"
    value = "grafana.${var.server_base_domain}"
  }

  set_sensitive {
    name  = "adminUser"
    value = random_password.admin_username.result
  }
  set_sensitive {
    name  = "adminPassword"
    value = random_password.admin_password.result
  }

  set {
    name  = "datasources.datasources\\.yaml.apiVersion"
    value = "1"
  }
  set {
    name  = "datasources.datasources\\.yaml.datasources[0].name"
    value = "Loki"
  }
  set {
    name  = "datasources.datasources\\.yaml.datasources[0].type"
    value = "loki"
  }
  set {
    name  = "datasources.datasources\\.yaml.datasources[0].access"
    value = "proxy"
  }
  set {
    name  = "datasources.datasources\\.yaml.datasources[0].url"
    value = "http://loki-gateway.${data.terraform_remote_state.loki.outputs.namespace}"
  }
  set {
    name  = "datasources.datasources\\.yaml.datasources[0].basicAuth"
    value = "true"
  }
  set_sensitive {
    name  = "datasources.datasources\\.yaml.datasources[0].basicAuthUser"
    value = "${data.terraform_remote_state.loki.outputs.gateway_username}"
  }
  set_sensitive {
    name  = "datasources.datasources\\.yaml.datasources[0].secureJsonData.basicAuthPassword"
    value = "${data.terraform_remote_state.loki.outputs.gateway_password}"
  }
}
