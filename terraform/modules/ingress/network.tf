resource "kubernetes_service" "internal" {
  count = local.is_endpoint_internal ? 1 : 0

  metadata {
    name      = "${var.name}-internal"
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

resource "kubernetes_service" "external" {
  count = local.is_endpoint_internal ? 0 : 1

  metadata {
    name      = "${var.name}-external"
    namespace = var.namespace
  }

  spec {
    external_name = var.external_name
    type          = "ExternalName"
  }
}

resource "kubernetes_manifest" "internal_ingress" {
  count = local.is_endpoint_internal ? 1 : 0

  manifest = {
    apiVersion = "traefik.io/v1alpha1"
    kind       = "IngressRoute"

    metadata = {
      name      = "${var.name}-internal"
      namespace = var.namespace
    }

    spec = {
      entryPoints = ["websecure"]

      routes = [{
        kind  = "Rule"
        match = "Host(`${var.domain}`)${"" != var.path ? " && PathPrefix(`/${var.path}`)" : ""}"

        priority = var.priority

        services = [{
          name      = one(kubernetes_service.internal[*].metadata[0].name)
          namespace = var.namespace
          port      = one(kubernetes_service.internal[*].spec[0].port[0].port)
        }]

        middlewares = local.middlewares
      }]
    }
  }
}

resource "kubernetes_manifest" "external_ingress" {
  count = local.is_endpoint_internal ? 0 : 1

  manifest = {
    apiVersion = "traefik.io/v1alpha1"
    kind       = "IngressRoute"

    metadata = {
      name      = "${var.name}-external"
      namespace = var.namespace
    }

    spec = {
      entryPoints = ["websecure"]

      routes = [{
        kind  = "Rule"
        match = "Host(`${var.domain}`)${"" != var.path ? " && PathPrefix(`/${var.path}`)" : ""}"

        priority = var.priority

        services = [{
          name      = one(kubernetes_service.external[*].metadata[0].name)
          namespace = var.namespace
          scheme    = var.is_external_scheme_http ? "http" : "https"
          port      = var.target_port
        }]

        middlewares = local.middlewares
      }]
    }
  }
}

locals {
  is_endpoint_internal = null != var.selector

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
