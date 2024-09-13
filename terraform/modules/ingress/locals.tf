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
