# Cap exposes two classes of route on the same host, with different auth needs:
#
#   - Public (browser widget + server-side verify): /<siteKey>/{challenge,reedeem},
#     /(siteKey/)?siteverify and /assets/*. These MUST be reachable without a
#     browser login or the widget can't function.
#   - Everything else is the admin dashboard (/, /server/*, /auth/*, /public/*,
#     /swagger) and must be protected.
#
# The dashboard paths interleave with the public ones at the host root and
# <siteKey> is a dynamic segment, so you can't safely "protect dashboard paths"
# by prefix (a siteKey root is indistinguishable from /server). Instead we
# default-deny the whole host with OIDC and carve out only the verified public
# endpoints. This fails safe: any endpoint missed below is bounced to Keycloak
# (loudly broken), never silently exposed.
#
# Both routes come from the ingress module (no hand-written IngressRoute). The
# Traefik priority on the public regex route (100) beats the OIDC catch-all (1),
# so matching requests skip auth; everything else falls through to OIDC.

# Call 1 - OIDC catch-all. Creates the cap-internal Service, the Keycloak client
# and the cap-auth-interactive middleware, and protects the whole host.
module "cap_ingress" {
  source = "../modules/ingress"

  name      = "cap"
  namespace = kubernetes_namespace.cap.metadata[0].name
  domain    = local.cap_domain

  selector    = { app = "cap" }
  target_port = 3000

  auth_mode           = "oidc-interactive"
  keycloak_auth_realm = "primary"

  # Cap's challenge endpoints are hit by end-user browsers worldwide; geoblock
  # would reject legitimate users in blocked regions. CrowdSec + Cloudflare stay
  # on (CrowdSec complements Cap's bot defences).
  do_enable_geoblock = false

  priority = 1
}

# Call 2 - public hole for the widget/verify endpoints. No auth. Reuses the
# service created by cap_ingress (named <name>-internal -> "cap-internal"). The
# regex requires a known second segment (challenge|redeem|siteverify|assets...),
# so it can never match /, /server, /auth or /public - those stay behind OIDC.
module "cap_public" {
  source = "../modules/ingress"

  name      = "cap-public"
  namespace = kubernetes_namespace.cap.metadata[0].name
  domain    = local.cap_domain

  existing_service_name      = "cap-internal"
  existing_service_namespace = kubernetes_namespace.cap.metadata[0].name
  target_port                = 80

  auth_mode = "none"

  do_enable_geoblock = false

  path_matcher = "PathRegexp"
  path         = "^/(?:[A-Za-z0-9_-]+/(challenge|redeem)|(?:[A-Za-z0-9_-]+/)?siteverify|assets/.+)$"

  priority = 100
}
