# OpenTelemetry Collector — the single OTLP sink for the cluster.
#
# Receivers: OTLP grpc (4317) + http (4318). Services point their
# OTEL_EXPORTER_OTLP_ENDPOINT at `otel-collector.otel.svc:4317` (gRPC) or
# `:4318` (HTTP). The operator creates the Service automatically.
#
# Traces  -> Tempo distributor (otlpgrpc, `tempo-distributor.tempo.svc:4317`).
# Metrics -> Prometheus remote-write receiver (`prometheusremotewrite` exporter
#            pushes to kube-prometheus-stack-prometheus:9090/api/v1/write; the
#            pull-style `prometheus` exporter is not in the
#            opentelemetry-collector-k8s distro in 0.156+, hence remote-write).
#
# k8sattributes enriches every span with k8s metadata (namespace/pod/node/
# deployment) using the collector's own service account; the RBAC it needs is in
# rbac.tf. The `resource` processor copies the dotted names (k8s.namespace.name)
# into undotted ones (namespace, pod) so the Tempo datasource's tracesToLogs.tags
# can match Loki's namespace/pod labels (Loki labels can't contain dots).
#
# The operator also exposes the collector's OWN self-telemetry (spans processed,
# queue depth, errors) on `otel-collector-monitoring:8888`; that is what the
# ServiceMonitor in servicemonitor.tf scrapes.
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

      # Use the contrib distribution rather than the operator's default
      # opentelemetry-collector-k8s image: the k8s distro ships only
      # otlp/debug/file/loadbalancing/otelarrow exporters and omits the
      # `prometheusremotewrite` exporter we use to bridge OTLP metrics into
      # Prometheus. contrib has everything the k8s distro has (k8sattributes,
      # resource, ...) plus prometheusremotewrite. Pinned to match the
      # operator's collector version.
      image = "ghcr.io/open-telemetry/opentelemetry-collector-releases/opentelemetry-collector-contrib:0.156.0"

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

          # Enrich spans with Kubernetes metadata via the API server (RBAC in
          # rbac.tf). auth_type=serviceAccount uses the collector's own SA.
          # Explicit `k8s_attributes` type (bare `k8sattributes` is deprecated).
          "k8s_attributes" = {
            auth_type = "serviceAccount"
            extract = {
              metadata = [
                "k8s.namespace.name",
                "k8s.pod.name",
                "k8s.node.name",
                "k8s.deployment.name",
              ]
            }
          }

          # Copy the canonical dotted k8s.* names into undotted `namespace` /
          # `pod` resource attributes that match Loki's label names, so Tempo's
          # tracesToLogs.tags (["namespace","pod"]) can narrow the log stream.
          resource = {
            attributes = [
              {
                key            = "namespace"
                action         = "upsert"
                from_attribute = "k8s.namespace.name"
              },
              {
                key            = "pod"
                action         = "upsert"
                from_attribute = "k8s.pod.name"
              },
            ]
          }

          # Normalize Temporal's per-role service.name down to a single
          # `temporal` service so all of its traces group together in
          # Grafana/Tempo, while preserving the role as `temporal.role`.
          #
          # WHY: Temporal's Go server composes ResourceServiceName as
          # `{OTEL_SERVICE_NAME}.{role}` (frontend/history/matching/worker)
          # rather than a single service name, so each role lands as its own
          # "service" in Tempo (temporal.frontend, temporal.history, ...),
          # fragmenting the service dropdown. This captures the role suffix
          # and flattens service.name to `temporal`. Runs after
          # k8s_attributes/resource (which don't touch service.name), before
          # batch. error_mode=ignore so a bad match never drops traces.
          #
          # Config shape note (transform 0.156): there is no top-level
          # `resource_statements` key; resource-attribute edits on the traces
          # pipeline are nested under `trace_statements` with context=resource.
          #
          # OTTL string escaping: the OTTL string literal "^temporal\\."
          # denotes the regex ^temporal\. (a literal dot anchor), so it only
          # rewrites names that start with "temporal." and leaves a bare
          # "temporal" untouched. The doubled backslash is OTTL's own string
          # escaping; each backslash is then re-escaped for HCL ("\\\\").
          #
          # OTTL function names are inconsistently cased in 0.156: IsMatch and
          # ExtractPatterns are CamelCase and RETURN a value (usable inside
          # set()), but the replacement helpers are snake_case
          # (replace_pattern/replace_all_patterns) and mutate their target
          # argument in place — they cannot be nested inside set(). So we (1)
          # copy service.name into temporal.role, (2) strip the "temporal."
          # prefix in place, (3) flatten service.name to "temporal".
          "transform/temporal" = {
            error_mode = "ignore"
            trace_statements = [
              {
                context = "resource"
                statements = [
                  "set(attributes[\"temporal.role\"], attributes[\"service.name\"]) where attributes[\"service.name\"] != nil and IsMatch(attributes[\"service.name\"], \"^temporal\\\\.\")",
                  "replace_pattern(attributes[\"temporal.role\"], \"^temporal\\\\.\", \"\") where attributes[\"temporal.role\"] != nil and IsMatch(attributes[\"temporal.role\"], \"^temporal\\\\.\")",
                  "set(attributes[\"service.name\"], \"temporal\") where attributes[\"service.name\"] != nil and IsMatch(attributes[\"service.name\"], \"^temporal\\\\.\")",
                ]
              },
            ]
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
          # Metrics -> Prometheus remote-write receiver (enabled on
          # kube-prometheus-stack via prometheus.prometheusSpec.enableRemoteWriteReceiver).
          # Explicit `prometheus_remote_write` type (the bare `prometheusremotewrite`
          # alias is deprecated in 0.156).
          "prometheus_remote_write" = {
            endpoint = "http://kube-prometheus-stack-prometheus.prometheus.svc.cluster.local:9090/api/v1/write"
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
              processors = ["memory_limiter", "k8s_attributes", "resource", "transform/temporal", "batch"]
              exporters  = ["otlp_grpc/tempo", "debug"]
            }
            metrics = {
              receivers  = ["otlp"]
              processors = ["memory_limiter", "batch"]
              exporters  = ["prometheus_remote_write"]
            }
          }
        }
      }
    }
  }
}
