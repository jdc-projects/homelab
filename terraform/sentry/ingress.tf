module "ingress" {
  source = "../modules/ingress"

  name      = "sentry"
  namespace = kubernetes_namespace.sentry.metadata[0].name
  domain    = local.sentry_domain

  target_port = 9000

  existing_service_name      = "sentry-web"
  existing_service_namespace = kubernetes_namespace.sentry.metadata[0].name
}
