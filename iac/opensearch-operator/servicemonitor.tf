# Metrics are served by the operator's controller-runtime HTTP server on port
# 8080 (bound to 0.0.0.0 via the manager.metricsBindAddress value in
# opensearch-operator.tf). The chart's own Service only exposes the (now
# vestigial) 8443/https port, so we create a dedicated Service that routes to
# 8080 and have the ServiceMonitor target it.
#
# Auth: v3 dropped kube-rbac-proxy in favor of controller-runtime's built-in
# WithAuthenticationAndAuthorization, which validates the scraper's bearer token
# via TokenReview + SubjectAccessReview over HTTPS (a request without a token is
# rejected with 401). The prometheus SA already holds get on the /metrics
# nonResourceURL (ClusterRole kube-prometheus-stack-prometheus), so its token is
# authorized — the ServiceMonitor forwards it via bearerTokenFile. The metrics
# server uses an internal/self-signed cert, so TLS verification is skipped.
resource "kubernetes_service" "opensearch_operator_metrics" {
  metadata {
    name      = "opensearch-operator-metrics"
    namespace = kubernetes_namespace.opensearch_operator.metadata[0].name

    labels = {
      "app.kubernetes.io/name"      = "opensearch-operator"
      "app.kubernetes.io/component" = "metrics"
    }
  }

  spec {
    port {
      name        = "http-metrics"
      port        = 8080
      target_port = "8080"
      protocol    = "TCP"
    }

    selector = {
      "app.kubernetes.io/name" = "opensearch-operator"
    }
  }
}

resource "kubernetes_manifest" "opensearch_operator_servicemonitor" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"

    metadata = {
      name      = "opensearch-operator"
      namespace = kubernetes_namespace.opensearch_operator.metadata[0].name
    }

    spec = {
      selector = {
        matchLabels = {
          "app.kubernetes.io/name"      = "opensearch-operator"
          "app.kubernetes.io/component" = "metrics"
        }
      }

      endpoints = [
        {
          port            = "http-metrics"
          path            = "/metrics"
          scheme          = "https"
          tlsConfig       = { insecureSkipVerify = true }
          bearerTokenFile = "/var/run/secrets/kubernetes.io/serviceaccount/token"
        }
      ]
    }
  }
}
