locals {
  # OTLP gRPC receiver on the cluster's otel-collector (Tempo backend).
  # Kept as a local rather than a variable so this stays self-contained in
  # temporal.tf; the module's only consumer is iac/posthog.
  otel_collector_endpoint = "otel-collector.otel.svc:4317"

  temporal_config = merge(
    {
      DB                       = "postgres12"
      DB_PORT                  = "5432"
      POSTGRES_USER            = "temporal"
      POSTGRES_SEEDS           = "${kubernetes_manifest.temporal_db.manifest.metadata.name}-rw"
      DYNAMIC_CONFIG_FILE_PATH = "config/dynamicconfig/development-sql.yaml"
    },
    var.es_host != null ? {
      ENABLE_ES  = "true"
      ES_SEEDS   = var.es_host
      ES_VERSION = var.es_version
      } : {
      ENABLE_ES = "false"
    }
  )
}

resource "kubernetes_config_map" "temporal_dynamic_config" {
  metadata {
    name      = "${var.name_prefix}-dynamic-config"
    namespace = var.namespace
  }

  data = {
    "development-sql.yaml" = <<-EOT
      limit.maxIDLength:
          - value: 255
            constraints: {}
      system.forceSearchAttributesCacheRefreshOnRead:
          - value: true
            constraints: {}
      system.visibilityDisableOrderByClause:
          - value: false
            constraints: {}
    EOT
  }
}

resource "kubernetes_config_map" "temporal_config" {
  metadata {
    name      = "${var.name_prefix}-config"
    namespace = var.namespace
  }

  data = local.temporal_config
}

# The auto-setup image's entrypoint renders /etc/temporal/config/docker.yaml
# (via dockerize) from its built-in config_template.yaml, then runs autosetup,
# then execs /etc/temporal/start-temporal.sh. That template has NO otel section,
# and Temporal's Go server reads observability config ONLY from this YAML — it
# does not honour the OTEL_* SDK env vars the way the OpenTelemetry SDK does.
# So we override start-temporal.sh to append an `otel` block (1.26's
# connections/exporters schema) to the rendered config immediately before
# temporal-server starts, exporting traces over OTLP gRPC to the cluster's
# otel-collector. See common/telemetry/config.go + env.go upstream.
resource "kubernetes_config_map" "temporal_otel" {
  metadata {
    name      = "${var.name_prefix}-otel"
    namespace = var.namespace
  }

  data = {
    "start-temporal.sh" = <<-EOT
      #!/bin/bash
      set -eu -o pipefail

      # Append the otel exporter section to the already-rendered server config.
      # Leading blank line separates it from the preceding dynamicConfigClient
      # block; the rest is plain YAML that temporal-server parses at startup.
      cat >> /etc/temporal/config/docker.yaml <<'OTEL'

      otel:
        exporters:
          - kind:
              signal: traces
              model: otlp
              protocol: grpc
            spec:
              connection:
                endpoint: ${local.otel_collector_endpoint}
                insecure: true
      OTEL

      : "$${SERVICES:=}"
      flags=()
      if [[ -n $${SERVICES} ]]; then
          SERVICES="$${SERVICES//:/,}"
          SERVICES="$${SERVICES//,/ }"
          for i in $SERVICES; do flags+=("--service=$i"); done
      fi

      exec temporal-server --env docker start "$${flags[@]}"
    EOT
  }
}

resource "kubernetes_deployment" "temporal" {
  metadata {
    name      = var.name_prefix
    namespace = var.namespace
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = var.name_prefix
      }
    }

    template {
      metadata {
        labels = {
          app = var.name_prefix
        }
      }

      spec {
        container {
          image = var.server_image
          name  = var.name_prefix

          env_from {
            config_map_ref {
              name = kubernetes_config_map.temporal_config.metadata[0].name
            }
          }

          env_from {
            secret_ref {
              name = kubernetes_secret.temporal_secrets.metadata[0].name
            }
          }

          # Temporal's config_template.yaml honours PROMETHEUS_ENDPOINT by adding
          # a `metrics.prometheus.listenAddress` block to the rendered config,
          # which makes the temporal server expose a Prometheus scrape endpoint.
          env {
            name  = "PROMETHEUS_ENDPOINT"
            value = "0.0.0.0:8001"
          }

          # OpenTelemetry tracing. The actual exporter is wired via the otel
          # block appended to docker.yaml by start-temporal.sh (see the
          # temporal_otel config map) — Temporal's Go server ignores the SDK
          # OTEL_EXPORTER_* env vars. OTEL_SERVICE_NAME is still honoured by
          # the server as the resource.service.name prefix (-> temporal.<svc>).
          env {
            name  = "OTEL_SERVICE_NAME"
            value = "temporal"
          }

          volume_mount {
            name       = "dynamic-config"
            mount_path = "/etc/temporal/config/dynamicconfig"
          }

          # Override the image's start-temporal.sh so the otel block is appended
          # to docker.yaml before temporal-server starts (subPath -> single file).
          volume_mount {
            name       = "otel-start-script"
            mount_path = "/etc/temporal/start-temporal.sh"
            sub_path   = "start-temporal.sh"
          }

          port {
            container_port = 7233
          }

          port {
            name           = "metrics"
            container_port = 8001
          }

          resources {
            requests = {
              cpu    = "250m"
              memory = "512Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "1Gi"
            }
          }
        }

        volume {
          name = "dynamic-config"
          config_map {
            name = kubernetes_config_map.temporal_dynamic_config.metadata[0].name
          }
        }

        volume {
          name = "otel-start-script"
          config_map {
            name         = kubernetes_config_map.temporal_otel.metadata[0].name
            default_mode = "0755"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "temporal" {
  metadata {
    name      = var.name_prefix
    namespace = var.namespace

    labels = {
      "app.kubernetes.io/name" = var.name_prefix
    }
  }

  spec {
    selector = {
      app = var.name_prefix
    }

    port {
      name        = "grpc"
      port        = 7233
      target_port = 7233
    }

    # Prometheus metrics port — exposed so ServiceMonitors can scrape the
    # endpoint served via PROMETHEUS_ENDPOINT=0.0.0.0:8001 on the container.
    port {
      name        = "metrics"
      port        = 8001
      target_port = "metrics"
    }
  }
}
