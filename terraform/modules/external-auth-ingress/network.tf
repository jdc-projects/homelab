resource "kubernetes_manifest" "forward_auth_headers_ingress" {
  manifest = {
    apiVersion = "traefik.io/v1alpha1"
    kind       = "IngressRoute"

    metadata = {
      name      = "forward-auth-headers"
      namespace = var.namespace
    }

    spec = {
      entryPoints = ["websecure"]

      routes = [{
        kind  = "Rule"
        match = "Host(`${var.url_subdomain}.${var.server_base_domain}`) && PathPrefix(`/oauth2/`)"
        services = [{
          name      = helm_release.oauth2_proxy.name
          namespace = data.terraform_remote_state.oauth2_proxy.outputs.middleware_namespace
          port      = "80"
        }]
        middlewares = [{
          name      = kubernetes_manifest.oauth2_proxy_headers_middleware.manifest["metadata"].name
          namespace = kubernetes_manifest.oauth2_proxy_headers_middleware.manifest["metadata"].namespace
        }]
      }]
    }
  }
}

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
        match = "Host(`${var.url_subdomain}.${var.server_base_domain}`)"
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
