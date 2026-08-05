resource "helm_release" "otel_operator" {
  name = "opentelemetry-operator"

  repository = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  chart      = "opentelemetry-operator"
  version    = "0.120.1"

  namespace = kubernetes_namespace.otel.metadata[0].name

  timeout = 300

  set = [
    # Operator + CRDs (OpenTelemetryCollector, Instrumentation, OpAMPBridge).
    {
      name  = "crds.create"
      value = "true"
    },
    # Webhook certs issued by the already-deployed cert-manager (chart spins up
    # its own self-signed Issuer when issuerRef is empty).
    {
      name  = "admissionWebhooks.certManager.enabled"
      value = "true"
    },
    # Self-monitoring: scraped by the cluster-wide select-all Prometheus.
    {
      name  = "manager.serviceMonitor.enabled"
      value = "true"
    },
  ]
}
