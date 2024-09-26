resource "helm_release" "cloudnative_pg" {
  name      = "cloudnative-pg"
  namespace = kubernetes_namespace.cloudnative_pg.metadata[0].name

  repository = "https://cloudnative-pg.github.io/charts"
  chart      = "cloudnative-pg"
  version    = "0.22.0"

  timeout = 60
}
