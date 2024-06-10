resource "kubernetes_config_map" "oauth2_proxy_env" {
  metadata {
    name      = "oauth2-proxy-env"
    namespace = kubernetes_namespace.oauth2_proxy.metadata[0].name
  }

  data = {
    OAUTH2_PROXY_PROVIDER     = "keycloak-oidc"
    OAUTH2_PROXY_ALLOWED_ROLE = keycloak_role.oauth2_proxy_admin.name

    OAUTH2_PROXY_REVERSE_PROXY = "true"
  }
}

resource "helm_release" "oauth2_proxy" {
  name = "oauth2-proxy"

  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart      = "oauth2-proxy"
  version    = "5.3.3"

  namespace = kubernetes_namespace.oauth2_proxy.metadata[0].name

  timeout = 300

  set {
    name  = "configuration.clientID"
    value = keycloak_openid_client.oauth2_proxy.client_id
  }
  set_sensitive {
    name  = "configuration.clientSecret"
    value = random_password.keycloak_client_secret.result
  }
  set_sensitive {
    name  = "configuration.cookieSecret"
    value = random_password.oauth2_proxy_cookie_secret.result
  }
  set {
    name  = "configuration.content"
    value = <<-EOF
      email_domains = [ "*" ]
      upstreams = [ "static://202" ]
    EOF
  }
  set {
    name  = "configuration.oidcIssuerUrl"
    value = data.terraform_remote_state.keycloak_config.outputs.keycloak_issuer_url
  }
  set {
    name  = "configuration.whiteList"
    value = "*.${var.server_base_domain}"
  }

  set {
    name  = "extraEnvVarsCM"
    value = kubernetes_config_map.oauth2_proxy_env.metadata[0].name
  }

  set {
    name  = "redis.master.persistence.existingClaim"
    value = kubernetes_persistent_volume_claim.oauth2_proxy.metadata[0].name
  }
  set {
    name  = "redis.volumePermissions.enabled"
    value = "true"
  }

  lifecycle {
    replace_triggered_by = [
      kubernetes_config_map.oauth2_proxy_env
    ]
  }
}
