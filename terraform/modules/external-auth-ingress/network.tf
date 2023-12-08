resource "kubernetes_service" "forward_auth" {
  metadata {
    name      = "forward-auth"
    namespace = var.namespace
  }

  spec {
    external_name = var.external_name
    type          = "ExternalName"
  }
}

resource "kubernetes_manifest" "forward_auth_ingress" {
  manifest = {
    apiVersion = "traefik.io/v1alpha1"
    kind       = "IngressRoute"

    metadata = {
      name      = "forward-auth"
      namespace = var.namespace
    }

    spec = {
      entryPoints = ["websecure"]

      routes = [{
        kind  = "Rule"
        match = "Host(`admin.${var.server_base_domain}`) && PathPrefix(`/${var.path_prefix}`)"
        services = [{
          name      = "forward-auth"
          namespace = var.namespace
          scheme    = var.external_scheme
          port      = var.external_port
        }]
        middlewares = [{
          name      = data.terraform_remote_state.oauth2_proxy.outputs.redirect_middleware_name
          namespace = data.terraform_remote_state.oauth2_proxy.outputs.middleware_namespace
        }]
      }]
    }
  }
}
