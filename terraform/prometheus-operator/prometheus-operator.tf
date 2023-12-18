locals {
  grafana_domain = "grafana.${var.server_base_domain}"
}

resource "helm_release" "prometheus_operator" {
  name      = "prometheus-operator"
  namespace = kubernetes_namespace.prometheus_operator.metadata[0].name

  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "55.5.0"

  timeout = 300

  set {
    name  = "grafana.defaultDashboardsEditable"
    value = "false"
  }
  set_sensitive {
    name  = "grafana.adminPassword"
    value = random_password.grafana_admin_password.result
  }
  set {
    name  = "grafana.ingress.enabled"
    value = "true"
  }
  set_list {
    name = "grafana.ingress.hosts"
    value = [
      local.grafana_domain,
    ]
  }
  set_list {
    name  = "grafana.extraConfigmapMounts"
    value = [

    ]
  }

  # set {
  #   name  = ""
  #   value = ""
  # }

  # set {
  #   name  = ""
  #   value = ""
  # }

  # set {
  #   name  = ""
  #   value = ""
  # }

  # set {
  #   name  = ""
  #   value = ""
  # }
}
