resource "helm_release" "promtail" {
  name = "promtail"

  repository = "https://grafana.github.io/helm-charts"
  chart      = "promtail"
  version    = "6.11.9"

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
    value = "containers"
  }
  set {
    name  = "defaultVolumes[1].hostPath.path"
    value = "/mnt/vault/ix-applications/docker/containers"
  }
  set {
    name  = "defaultVolumes[2].name"
    value = "pods"
  }
  set {
    name  = "defaultVolumes[2].hostPath.path"
    value = "/var/lib/kubelet/pods"
  }

  set {
    name  = "config.clients[0].url"
    value = "http://loki-gateway/loki/api/v1/push"
  }
}
