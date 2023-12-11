resource "helm_release" "postgres_operator" {
  name      = "postgres-operator"
  namespace = kubernetes_namespace.postgres_operator.metadata[0].name

  repository = "https://opensource.zalando.com/postgres-operator/charts/postgres-operator"
  chart      = "postgres-operator"
  version    = "1.10.1"

  timeout = 300

  set {
    name  = "configGeneral.workers"
    value = "3"
  }

  set {
    name  = "configMajorVersionUpgrade.major_version_upgrade_mode"
    value = "full"
  }

  set {
    name  = "configKubernetes.enable_readiness_probe"
    value = "true"
  }
}
