resource "kubernetes_manifest" "n8n_instrumentation" {
  manifest = {
    apiVersion = "opentelemetry.io/v1alpha1"
    kind       = "Instrumentation"
    metadata = {
      name      = "nodejs"
      namespace = kubernetes_namespace.n8n.metadata[0].name
    }
    spec = {
      exporter = {
        endpoint = "http://otel-collector.otel.svc:4318"
      }
      propagators = ["tracecontext", "baggage"]
      nodejs = {
        env = [
          {
            name  = "OTEL_SERVICE_NAME"
            value = "n8n"
          }
        ]
      }
    }
  }
}
