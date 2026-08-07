module "temporal" {
  source = "../modules/temporal"

  namespace       = kubernetes_namespace.posthog.metadata[0].name
  is_db_hibernate = var.is_db_hibernate
  es_host         = "opensearch"
  cors_origins    = "https://posthog.${var.server_base_domain}"
  ui_domain       = "temporal.${var.server_base_domain}"

  ingress_module_source = "../ingress"

  depends_on = [kubernetes_manifest.opensearch]
}
