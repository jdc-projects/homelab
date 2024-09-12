resource "helm_release" "promtail" {
  name = "promtail"

  repository = "https://grafana.github.io/helm-charts"
  chart      = "promtail"
  version    = "6.16.5"

  namespace = kubernetes_namespace.loki.metadata[0].name

  timeout = 300

  set {
    name  = "defaultVolumes[0].name"
    value = "run"
  }
  set {
    name  = "defaultVolumes[0].hostPath.path"
    value = "/run/promtail"
  }
  set {
    name  = "defaultVolumes[1].name"
    value = "pods"
  }
  set {
    name  = "defaultVolumes[1].hostPath.path"
    value = "/var/log/pods"
  }
  set {
    name  = "defaultVolumes[2].name"
    value = "mnt"
  }
  set {
    name  = "defaultVolumes[2].hostPath.path"
    value = "/mnt"
  }

  set {
    name  = "defaultVolumeMounts[0].name"
    value = "run"
  }
  set {
    name  = "defaultVolumeMounts[0].mountPath"
    value = "/run/promtail"
  }
  set {
    name  = "defaultVolumeMounts[1].name"
    value = "pods"
  }
  set {
    name  = "defaultVolumeMounts[1].mountPath"
    value = "/var/log/pods"
  }
  set {
    name  = "defaultVolumeMounts[1].readOnly"
    value = "true"
  }
  set {
    name  = "defaultVolumeMounts[2].name"
    value = "mnt"
  }
  set {
    name  = "defaultVolumeMounts[2].mountPath"
    value = "/mnt"
  }
  set {
    name  = "defaultVolumeMounts[2].readOnly"
    value = "true"
  }

  set {
    name  = "config.logLevel"
    value = "info"
  }
  set {
    name  = "config.logFormat"
    value = "json"
  }
  set {
    name  = "config.clients[0].url"
    value = "http://${helm_release.loki.name}-gateway/loki/api/v1/push"
  }
  set_sensitive {
    name  = "config.clients[0].basic_auth.username"
    value = random_password.gateway_username.result
  }
  set_sensitive {
    name  = "config.clients[0].basic_auth.password"
    value = random_password.gateway_password.result
  }
}
