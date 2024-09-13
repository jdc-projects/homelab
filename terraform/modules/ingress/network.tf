resource "kubernetes_service" "service" {
  metadata {
    name      = var.name
    namespace = var.namespace
  }

  spec {
    selector = var.selector

    port {
      port        = 80
      target_port = var.target_port
    }
  }
}

resource "kubernetes_manifest" "ingress" {
  manifest = {
    apiVersion = "traefik.io/v1alpha1"
    kind       = "IngressRoute"

    metadata = {
      name      = var.name
      namespace = var.namespace
    }

    spec = {
      entryPoints = ["websecure"]

      routes = [{
        kind  = "Rule"
        match = "Host(`${var.domain}`)${"" != var.path ? " && PathPrefix(`/${var.path}`)" : ""}"

        services = [{
          name      = kubernetes_service.service.metadata[0].name
          namespace = var.namespace
          port      = kubernetes_service.service.spec[0].port[0].port
        }]

        middlewares = local.middlewares
      }]
    }
  }
}

locals {
  middlewares = concat(
    var.do_enable_cloudflare_real_ip_middleware ? [{
      name      = "cloudflare-real-ip"
      namespace = data.terraform_remote_state.traefik.outputs.traefik_namespace
    }] : [],
    var.do_enable_geoblock ? [{
      name      = "geoblock"
      namespace = data.terraform_remote_state.traefik.outputs.traefik_namespace
    }] : [],
    var.do_enable_crowdsec_bouncer ? [{
      name      = "crowdsec-bouncer"
      namespace = data.terraform_remote_state.traefik.outputs.traefik_namespace
    }] : [],
    var.do_enable_api_key_auth ? [{
      name      = one(kubernetes_manifest.api_key_auth_plugin_middleware[*].manifest.metadata.name)
      namespace = var.namespace
    }] : [],
    var.do_enable_keycloak_auth ? [{
      name      = one(kubernetes_manifest.keycloak_auth_plugin_middleware[*].manifest.metadata.name)
      namespace = var.namespace
    }] : [],
    var.extra_middlewares
  )
}
