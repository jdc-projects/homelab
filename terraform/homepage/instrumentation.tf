# OpenTelemetry auto-instrumentation for the Node.js homepage pod.
# The opentelemetry-operator's mutation webhook injects the Node.js OTEL SDK
# into any pod annotated `instrumentation.opentelemetry.io/inject-nodejs: "true"`
# (see the annotation on the deployment pod template in homepage.tf). The SDK
# exports traces over OTLP/HTTP to the cluster collector, which forwards them
# to Tempo.
resource "kubernetes_manifest" "homepage_instrumentation" {
  manifest = {
    apiVersion = "opentelemetry.io/v1alpha1"
    kind       = "Instrumentation"
    metadata = {
      name      = "nodejs"
      namespace = kubernetes_namespace.homepage.metadata[0].name
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
            value = "homepage"
          }
        ]
      }
    }
  }
}
