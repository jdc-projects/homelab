# OpenTelemetry Collector — the single OTLP sink for the cluster.
#
# Receivers: OTLP grpc (4317) + http (4318). Services point their
# OTEL_EXPORTER_OTLP_ENDPOINT at `otel-collector.otel.svc:4317` (gRPC) or
# `:4318` (HTTP). The operator creates the Service automatically.
#
# Traces -> Tempo distributor (otlpgrpc, `tempo-distributor.tempo.svc:4317`).
#
# Traces-only for now: the `prometheus` exporter (pull-style, :8889) was removed
# from the opentelemetry-collector-k8s distribution (0.156+ ships only
# otlp/debug/file/loadbalancing/otelarrow exporters). When a service needs OTLP
# metrics bridged into Prometheus, the right move is enabling the Prometheus
# remote-write receiver and using the `prometheusremotewrite` exporter here -
# that's a follow-up alongside the first service that needs it.
#
# The operator still exposes the collector's OWN self-telemetry (spans
# processed, queue depth, errors) on `otel-collector-monitoring:8888`; that is
# what the ServiceMonitor in servicemonitor.tf scrapes.
#
# v1 scope (platform only, no services instrumented yet): deliberately lean -
# memory_limiter + batch only. When the first service is instrumented, add a
# k8sattributes processor (with its RBAC) so traces carry namespace/pod
# resource attributes that the Tempo datasource tracesToLogs.tags can match
# against Loki's namespace/pod labels.
resource "kubernetes_manifest" "otel_collector" {
  manifest = {
    apiVersion = "opentelemetry.io/v1beta1"
    kind       = "OpenTelemetryCollector"

    metadata = {
      name      = "otel"
      namespace = local.namespace
    }

    spec = {
      mode = "deployment"

      # Explicit ports so the operator-generated Service exposes the OTLP
      # receivers. The collector's own metrics live on the operator-managed
      # otel-collector-monitoring:8888 Service (separate).
      ports = [
        {
          name       = "otlp-grpc"
          port       = 4317
          targetPort = "otlp-grpc"
          protocol   = "TCP"
        },
        {
          name       = "otlp-http"
          port       = 4318
          targetPort = "otlp-http"
          protocol   = "TCP"
        },
      ]

      resources = {
        requests = {
          cpu    = "100m"
          memory = "256Mi"
        }
        limits = {
          cpu    = "500m"
          memory = "512Mi"
        }
      }

      config = {
        receivers = {
          otlp = {
            protocols = {
              grpc = {
                endpoint = "0.0.0.0:4317"
              }
              http = {
                endpoint = "0.0.0.0:4318"
              }
            }
          }
        }

        processors = {
          memory_limiter = {
            check_interval         = "1s"
            limit_percentage       = 80
            spike_limit_percentage = 25
          }
          batch = {
            timeout         = "5s"
            send_batch_size = 1024
          }
        }

        exporters = {
          # Traces -> Tempo distributor over gRPC (explicit otlp_grpc type; the
          # bare `otlp` alias is deprecated in 0.156).
          "otlp_grpc/tempo" = {
            endpoint = "tempo-distributor.tempo.svc.cluster.local:4317"
            tls = {
              insecure = true
            }
          }
          # Useful while standing the pipeline up; lower verbosity or remove
          # once traces are flowing from real services.
          debug = {
            verbosity = "basic"
          }
        }

        service = {
          pipelines = {
            traces = {
              receivers  = ["otlp"]
              processors = ["memory_limiter", "batch"]
              exporters  = ["otlp_grpc/tempo", "debug"]
            }
          }
        }
      }
    }
  }
}
