module "whoami_ingress" {
  source = "../modules/ingress"

  name        = "whoami"
  namespace   = kubernetes_namespace.whoami.metadata[0].name
  domain      = "whoami.${var.server_base_domain}"
  target_port = 80
  selector = {
    app = "whoami"
  }

  do_enable_keycloak_auth = true
}
