# Sentry is fronted by two IngressRoutes (web + relay), both via the shared
# ingress module. Sentry handles its own SSO (sentry-auth-oidc), so neither route
# uses edge auth.
#
# Relay (ingestion) must catch /api/store, /api/0/relays, and /api/<numeric
# project id>/* — a regex, so it uses path_matcher = "PathRegexp". Everything
# else (including /api/0/* management API) falls through to the web catch-all.
# Traefik resolves overlap by priority (relay 100 > web 1).

module "sentry_relay_ingress" {
  source = "../modules/ingress"

  name      = "sentry-relay"
  namespace = local.ns
  domain    = local.sentry_domain

  path         = "^/api/(store|0/relays|[1-9][0-9]*)"
  path_matcher = "PathRegexp"
  priority     = 100

  existing_service_name      = local.sentry_relay_svc
  existing_service_namespace = local.ns
  target_port                = local.sentry_relay_port

  auth_mode                         = "none"
  do_enable_crowdsec_bouncer_appsec = false
}

module "sentry_web_ingress" {
  source = "../modules/ingress"

  name      = "sentry-web"
  namespace = local.ns
  domain    = local.sentry_domain

  # Host-only catch-all.
  path     = ""
  priority = 1

  existing_service_name      = local.sentry_web_svc
  existing_service_namespace = local.ns
  target_port                = local.sentry_web_port

  auth_mode                         = "none"
  do_enable_crowdsec_bouncer_appsec = false

  depends_on = [module.sentry_relay_ingress]
}
