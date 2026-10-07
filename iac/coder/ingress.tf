locals {
  # jd-chapman.dev -> jd-chapman[.]dev (regexp-safe dots).
  base_domain_regexp_safe = replace(var.server_base_domain, ".", "[.]")
}

# Dashboard / API route. Coder does its own auth (Keycloak OIDC) - gateway
# auth modes would break the CLI, websockets and workspace connections.
module "coder_ingress" {
  source = "../modules/ingress"

  name      = "coder"
  namespace = kubernetes_namespace.coder.metadata[0].name
  domain    = local.coder_domain

  existing_service_name      = helm_release.coder.name
  existing_service_namespace = kubernetes_namespace.coder.metadata[0].name
  target_port                = 80
}

# Workspace-app wildcard route: coderd serves workspace apps (code-server,
# port-forwards) on generated <app>--<workspace>--<user>-coder.<domain>
# hostnames (CODER_WILDCARD_ACCESS_URL suffix form) and disambiguates by Host
# header. The suffix form keeps every generated hostname a SINGLE label under
# the base domain, so the existing proxied *.jd-chapman.dev DNS record and the
# cluster's default wildcard TLS cert cover them - no second-level wildcard
# (which Cloudflare edge TLS would not serve without Advanced Certificate
# Manager; see developers.cloudflare.com/ssl/edge-certificates/universal-ssl/
# limitations). modules/ingress only emits exact Host() matches, so this route
# is hand-rolled with the same shared middleware chain (cloudflare, geoblock,
# crowdsec-bouncer).
#
# The regex requires a non-empty label ending in "-coder", so it can never
# capture the apex Host(`coder.<domain>`) route above; "-coder" is effectively
# a reserved hostname suffix on the zone.
resource "kubernetes_manifest" "coder_apps_ingress" {
  manifest = {
    apiVersion = "traefik.io/v1alpha1"
    kind       = "IngressRoute"

    metadata = {
      name      = "coder-apps-wildcard"
      namespace = kubernetes_namespace.coder.metadata[0].name
    }

    spec = {
      entryPoints = ["websecure"]

      routes = [{
        kind = "Rule"

        match = "HostRegexp(`^[a-zA-Z0-9-]+-coder[.]${local.base_domain_regexp_safe}$`)"

        services = [{
          name      = helm_release.coder.name
          namespace = kubernetes_namespace.coder.metadata[0].name
          port      = 80
          scheme    = "http"
        }]

        middlewares = [
          {
            name      = "cloudflare"
            namespace = data.terraform_remote_state.traefik.outputs.traefik_namespace
          },
          {
            name      = "geoblock"
            namespace = data.terraform_remote_state.traefik.outputs.traefik_namespace
          },
          {
            name      = "crowdsec-bouncer"
            namespace = data.terraform_remote_state.traefik.outputs.traefik_namespace
          },
        ]
      }]
    }
  }
}
