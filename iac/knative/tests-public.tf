# Tier-2 public test: a cluster-local ksvc exposed through the shared ingress
# module. This is the canonical pattern for internet-facing functions: Knative
# owns autoscaling/scale-to-zero, the ingress module owns TLS (wildcard cert),
# the shared middleware chain (cloudflare/geoblock/crowdsec), and auth. Set here
# to auth_mode="none" to prove the routing/TLS/middleware path cleanly; flip to
# "oidc-interactive" (or "api-key"/"oidc-api") for the production pattern — see
# iac/knative/README.md.

resource "kubernetes_manifest" "fn_public" {
  count = var.enable_tests.public ? 1 : 0

  manifest = {
    apiVersion = "serving.knative.dev/v1"
    kind       = "Service"

    metadata = {
      name      = "fn-public"
      namespace = local.test_ns

      # cluster-local: Knative must NOT publish this via its own (Tier-1)
      # ingress. The ingress module below is the sole public path.
      labels = {
        "networking.knative.dev/visibility" = "cluster-local"
      }

      annotations = {
        "homelab.jdc/purpose" = "Tier-2: cluster-local ksvc exposed via the shared ingress module (TLS + middlewares + auth)"
      }
    }

    spec = {
      template = {
        spec = {
          containers = [{ image = local.test_image_http }]
        }
      }
    }
  }

  computed_fields = ["metadata.labels", "metadata.annotations"]
}

module "fn_public_ingress" {
  count = var.enable_tests.public ? 1 : 0

  source = "../modules/ingress"

  name      = "fn-public"
  namespace = local.test_ns
  domain    = "fn-public.${var.server_base_domain}"

  # Point the IngressRoute at the direct Service that selects the ksvc's
  # revision pods (see kubernetes_service.fn_public_direct below).
  existing_service_name      = "fn-public-direct"
  existing_service_namespace = local.test_ns
  target_port                = 80

  auth_mode = "none"

  depends_on = [kubernetes_manifest.fn_public]
}

# Direct ClusterIP Service that selects the ksvc's revision pods. This is needed
# because the Traefik Knative provider can't handle the Tier-2 hairpin:
#
#  1. The ksvc's own Service (fn-public) is ExternalName → traefik-internal. The
#     Traefik Knative provider's buildServers() rejects ExternalName (no
#     ClusterIP), so a DomainMapping Kingress pointing at it is silently dropped.
#  2. The provider also has a TODO for rewriteHost (the DomainMapping Kingress
#     uses rewriteHost to bridge the external domain to the cluster-local one).
#
# So instead of the hairpin (Tier-2 → ExternalName → traefik-internal → knative
# entrypoint → revision), we route Tier-2 → this direct Service → revision pods.
#
# Limitation: this bypasses the activator, so scale-to-zero wake-up doesn't
# work via this path. The ksvc still scales to zero; a request arriving here
# while scaled down gets 503 (no endpoints). For production functions that need
# scale-to-zero + external TLS/auth, either pin minReplicas=1 or wait for the
# Traefik provider to support rewriteHost + ExternalName.
resource "kubernetes_service" "fn_public_direct" {
  count = var.enable_tests.public ? 1 : 0

  metadata {
    name      = "fn-public-direct"
    namespace = local.test_ns

    annotations = {
      "homelab.jdc/purpose" = "Direct Service selecting ksvc revision pods (bypasses the Kingress hairpin for Tier-2)"
    }
  }

  spec {
    selector = {
      "serving.knative.dev/service" = "fn-public"
    }

    port {
      name        = "http"
      port        = 80
      target_port = 8012
    }
  }

  depends_on = [kubernetes_manifest.fn_public]
}
