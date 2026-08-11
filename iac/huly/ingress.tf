locals {
  ns = kubernetes_namespace.huly.metadata[0].name

  # Huly's NGINIX chart uses `rewrite-target: /$2` on `/_accounts(/|$)(.*)`
  # to strip the `/_<name>` prefix before forwarding. We replicate that with
  # Traefik StripPrefix middlewares so the backend services see `/login`
  # rather than `/_accounts/login`. The catch-all (front) route doesn't need
  # stripping.
  #
  # ─── Auth gating ────────────────────────────────────────────────────────
  # Huly's `signUp` RPC at `POST /_accounts/` is open to anyone when
  # `disableSignup=false` (which we need for OIDC auto-provisioning — see
  # huly.tf). Source: hcengineering/platform/server/account-service/src/index.ts
  # (DISABLE_SIGNUP gates both OIDC auto-provision AND the signUp RPC method
  # via a single boolean — there is no upstream flag to enable one without
  # the other). To gate it without forking Huly, we put the traefik-oidc-auth
  # plugin in front of the account RPC endpoint.
  #
  # The plugin creates a per-middleware session cookie, so each gated
  # IngressRoute needs to share the SAME middleware instance (otherwise the
  # cookie minted on one route isn't recognised on another, and the SPA's
  # XHR calls fail). We create the middleware once on the front catch-all
  # (module.huly_front_ingress), then reference it by name from the accounts
  # RPC route via extra_middlewares. Both routes then share one session
  # cookie / Keycloak client.
  #
  # Route layout:
  #   - /_accounts/auth  (priority 100, no auth) — Huly's OIDC start +
  #     callback must be reachable without a gateway session, else the
  #     OIDC flow itself can't bootstrap.
  #   - /_accounts       (priority 50, shared auth) — everything else under
  #     /_accounts/, including POST /_accounts/ where signUp lives, AND
  #     including GET /_accounts/providers which the SPA fetches to render
  #     the login screen. The shared middleware gates all of these; the
  #     session is established when the user loads / (next route).
  #   - /                (priority 1, oidc-interactive, OWNS the middleware)
  #     — forces gateway auth on app load. Keycloak SSO makes this silent
  #     after Huly's own OIDC flow completes.
  #
  # ⚠️ UPDATE GUARD: if Huly renames /_accounts/, moves the signUp RPC, or
  # adds new account-creation endpoints on a different path, this gating
  # will silently miss and re-expose signup to the internet. Before bumping
  # `hulyVersion` or `chart.version` in huly.tf:
  #   1. Diff hcengineering/huly-selfhost's templates/account/deployment.yaml
  #      and templates/configmap.yaml for new env vars / endpoint changes.
  #   2. Grep hcengineering/platform/server/account-service/src/index.ts for
  #      the routes that handle `signUp` / `signUpOtp` / new account methods.
  #   3. Verify `curl -X POST https://<domain>/_accounts/ -d '{"method":"signUp",...}'`
  #      still returns 401 (not 200) post-upgrade.
  # See discussion in the module README and AGENTS.md "Observability" section.

  # Routes handled by the simple for_each below — none of these need auth.
  unauth_routes = {
    accounts-auth = {
      svc      = "account"
      port     = 3000
      priority = 100
      path     = "_accounts/auth"
      strip    = "_accounts"
    }
    transactor = {
      svc      = "transactor"
      port     = 3333
      priority = 100
      path     = "_transactor"
      strip    = "_transactor"
    }
    collaborator = {
      svc      = "collaborator"
      port     = 3078
      priority = 100
      path     = "_collaborator"
      strip    = "_collaborator"
    }
    rekoni = {
      svc      = "rekoni"
      port     = 4004
      priority = 90
      path     = "_rekoni"
      strip    = "_rekoni"
    }
    stats = {
      svc      = "stats"
      port     = 4900
      priority = 90
      path     = "_stats"
      strip    = "_stats"
    }
  }
}

# One StripPrefix middleware per path-routed backend.
resource "kubernetes_manifest" "strip_prefix" {
  for_each = local.unauth_routes

  manifest = {
    apiVersion = "traefik.io/v1alpha1"
    kind       = "Middleware"

    metadata = {
      name      = "huly-${each.key}-strip-prefix"
      namespace = local.ns
    }

    spec = {
      stripPrefix = {
        prefixes = ["/${each.value.strip}"]
      }
    }
  }
}

# StripPrefix middleware for the gated accounts RPC route (lives outside
# unauth_routes so we have a stable name to reference from the module block).
resource "kubernetes_manifest" "accounts_strip_prefix" {
  manifest = {
    apiVersion = "traefik.io/v1alpha1"
    kind       = "Middleware"

    metadata = {
      name      = "huly-accounts-rpc-strip-prefix"
      namespace = local.ns
    }

    spec = {
      stripPrefix = {
        prefixes = ["/_accounts"]
      }
    }
  }
}

# Unauthenticated path-routed backends.
module "huly_ingress" {
  for_each = local.unauth_routes
  source   = "../modules/ingress"

  name      = "huly-${each.key}"
  namespace = local.ns
  domain    = local.huly_domain
  path      = each.value.path
  priority  = each.value.priority

  existing_service_name      = each.value.svc
  existing_service_namespace = local.ns
  target_port                = each.value.port

  do_enable_crowdsec_bouncer_appsec = false
  do_enable_geoblock                = false

  extra_middlewares = [{
    name      = kubernetes_manifest.strip_prefix[each.key].manifest.metadata.name
    namespace = local.ns
  }]
}

# Catch-all for the front UI. No StripPrefix — Huly's front service owns
# the root path. This route OWNS the oidc-interactive middleware that the
# accounts RPC route below also references, so both share one session
# cookie / Keycloak client.
module "huly_front_ingress" {
  source = "../modules/ingress"

  name      = "huly-front"
  namespace = local.ns
  domain    = local.huly_domain
  path      = ""
  priority  = 1

  existing_service_name      = "front"
  existing_service_namespace = local.ns
  target_port                = 8080

  auth_mode = "oidc-interactive"

  do_enable_crowdsec_bouncer_appsec = false
  do_enable_geoblock                = false
}

# Account RPC route (POST /_accounts/ where signUp lives). Auth via the
# SHARED middleware owned by the front route above — same session cookie
# works on both routes.
module "huly_accounts_ingress" {
  source = "../modules/ingress"

  name      = "huly-accounts"
  namespace = local.ns
  domain    = local.huly_domain
  path      = "_accounts"
  priority  = 50

  existing_service_name      = "account"
  existing_service_namespace = local.ns
  target_port                = 3000

  # Auth mode is "none" at the module level (we don't want this module
  # instance creating its own middleware), but we attach the front route's
  # middleware via extra_middlewares so this route shares its session.
  do_enable_crowdsec_bouncer_appsec = false
  do_enable_geoblock                = false

  extra_middlewares = [
    {
      name      = module.huly_front_ingress.auth_interactive_middleware_name
      namespace = module.huly_front_ingress.auth_interactive_middleware_namespace
    },
    {
      name      = kubernetes_manifest.accounts_strip_prefix.manifest.metadata.name
      namespace = local.ns
    }
  ]
}
