module "grafana_ingress" {
  source = "../modules/ingress"

  name      = "grafana"
  namespace = kubernetes_namespace.grafana.metadata[0].name
  domain    = local.grafana_domain

  target_port = 3000

  existing_service_name      = "${kubernetes_manifest.grafana_deployment.manifest.metadata.name}-service"
  existing_service_namespace = kubernetes_manifest.grafana_deployment.manifest.metadata.namespace
}
