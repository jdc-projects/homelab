# OpenTelemetry Operator auto-instrumentation for the erpnext Python pods.
#
# With this Instrumentation CR present in the namespace and the pod template
# annotated `instrumentation.opentelemetry.io/inject-python: "true"`, the
# opentelemetry-operator webhook mutates new pods to attach the Python OTEL SDK
# (via an init-container that installs the SDK into the app image's
# site-packages and prepends it to PYTHONPATH). Spans are exported over
# OTLP/HTTP to the central collector (`otel-collector.otel.svc:4318`), which
# forwards traces to Tempo. OTEL_SERVICE_NAME is set explicitly so spans are
# attributed to `erpnext` rather than the auto-derived container/pod name.
resource "kubernetes_manifest" "erpnext_instrumentation" {
  manifest = {
    apiVersion = "opentelemetry.io/v1alpha1"
    kind       = "Instrumentation"

    metadata = {
      name      = "python"
      namespace = kubernetes_namespace.erpnext.metadata[0].name
    }

    spec = {
      exporter = {
        endpoint = "http://otel-collector.otel.svc:4318"
      }

      propagators = ["tracecontext", "baggage"]

      python = {
        env = [
          {
            name  = "OTEL_SERVICE_NAME"
            value = "erpnext"
          }
        ]
      }
    }
  }
}
