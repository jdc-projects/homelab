locals {
  chart_repository = "oci://ghcr.io/mariadb-operator/charts"
  chart_version    = "26.6.0"
}

resource "helm_release" "mariadb_operator_crds" {
  name      = "mariadb-operator-crds"
  namespace = kubernetes_namespace.mariadb_operator.metadata[0].name

  repository = local.chart_repository
  chart      = "mariadb-operator-crds"
  version    = local.chart_version

  timeout = 300
}

resource "helm_release" "mariadb_operator" {
  name      = "mariadb-operator"
  namespace = kubernetes_namespace.mariadb_operator.metadata[0].name

  repository = local.chart_repository
  chart      = "mariadb-operator"
  version    = local.chart_version

  timeout = 300

  set = [
    {
      name  = "metrics.enabled"
      value = "true"
    },
  ]

  depends_on = [helm_release.mariadb_operator_crds]
}
