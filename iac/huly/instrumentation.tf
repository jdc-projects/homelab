resource "kubernetes_manifest" "huly_instrumentation" {
  manifest = {
    apiVersion = "opentelemetry.io/v1alpha1"
    kind       = "Instrumentation"

    metadata = {
      name      = "nodejs"
      namespace = kubernetes_namespace.huly.metadata[0].name
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
            value = "huly"
          }
        ]
      }
    }
  }
}
