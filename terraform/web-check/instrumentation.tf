# OpenTelemetry Operator auto-instrumentation for the Node.js web-check pod.
#
# With this Instrumentation CR present in the namespace and the pod template
# annotated `instrumentation.opentelemetry.io/inject-nodejs: "true"`, the
# opentelemetry-operator webhook mutates new pods to attach the Node OTEL SDK
# (via an init-container that copies the SDK into the app image's node_modules
# and sets NODE_OPTIONS to require it). Spans are exported over OTLP/HTTP to
# the central collector (`otel-collector.otel.svc:4318`), which forwards traces
# to Tempo. OTEL_SERVICE_NAME is set explicitly so spans are attributed to
# `web-check` rather than the auto-derived container/pod name.
resource "kubernetes_manifest" "web_check_instrumentation" {
  manifest = {
    apiVersion = "opentelemetry.io/v1alpha1"
    kind       = "Instrumentation"

    metadata = {
      name      = "nodejs"
      namespace = kubernetes_namespace.web_check.metadata[0].name
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
            value = "web-check"
          }
        ]
      }
    }
  }
}
