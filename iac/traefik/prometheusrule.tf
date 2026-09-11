# Edge TLS certificate expiry alerting, owned by the homelab. (Apps used to
# alert on this themselves - xitter's XitterCertExpiringSoon existed only
# because "the homelab defines no cert-expiry alert of its own"; it can retire
# its rule now that this exists.)
#
# The inner `max by (cn, sans)` dedupes to the newest expiry per certificate
# CN before taking the min. Do NOT simplify to plain
# `min(traefik_tls_certs_not_after)`: Traefik never deletes the series of a
# replaced certificate (upstream bug traefik/traefik#8606), so after each
# in-place cert-manager renewal the old serial's gauge leaks into Prometheus
# with its stale notAfter and a plain min() false-fires on the ghost series
# (e.g. XitterCertExpiringSoon on 2026-09-11). With the per-CN dedupe a real
# renewal failure still leaves exactly one old series per CN and still alerts.
resource "kubernetes_manifest" "traefik_tls_cert_expiry_rule" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "PrometheusRule"

    metadata = {
      name      = "traefik-tls-cert-expiry"
      namespace = kubernetes_namespace.traefik.metadata[0].name
    }

    spec = {
      groups = [
        {
          name = "traefik.tls"
          rules = [
            {
              alert = "EdgeTLSCertExpiringSoon"
              # Plain min() false-positives after in-place cert renewals per
              # traefik#8606 (leaked stale-serial gauge series) - see the
              # comment at the top of this file.
              expr  = "min(max by (cn, sans) (traefik_tls_certs_not_after)) - time() < 14 * 24 * 3600"
              "for" = "1h"
              labels = {
                severity = "warning"
              }
              annotations = {
                summary     = "Edge TLS certificate expiring within 14 days"
                description = "The newest certificate for CN {{ $labels.cn }} served by the edge Traefik (namespace traefik) expires in {{ $value | humanizeDuration }}. If cert-manager is healthy it should already be renewing it; check Certificate/wildcard and secret wildcard-cert in namespace traefik."
              }
            }
          ]
        }
      ]
    }
  }
}
