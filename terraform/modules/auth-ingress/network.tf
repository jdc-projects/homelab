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
          name      = data.terraform_remote_state.oauth2_proxy.outputs.service_name
          namespace = data.terraform_remote_state.oauth2_proxy.outputs.namespace
          port      = "80"
        }]
        middlewares = [{
          name      = data.terraform_remote_state.oauth2_proxy.outputs.headers_middleware_name
          namespace = data.terraform_remote_state.oauth2_proxy.outputs.namespace
        }]
      }]
    }
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
          name      = var.service_name
          namespace = var.namespace
          port      = var.service_port
        }]
        middlewares = [{
          name      = data.terraform_remote_state.oauth2_proxy.outputs.redirect_middleware_name
          namespace = data.terraform_remote_state.oauth2_proxy.outputs.namespace
        }]
      }]
    }
  }
}
