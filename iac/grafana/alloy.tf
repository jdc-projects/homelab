# Grafana Alloy — the cluster's log collector (DaemonSet), successor to
# Promtail, which reached end-of-life on 2026-03-02 (capabilities merged into
# Alloy alongside Loki 3.4).  Replaces the former promtail helm_release: same
# namespace, same loki-gateway push target, same stream labels (app / instance
# / component / node_name / namespace / job=<namespace>/<app> / pod / container)
# and the same traceId structured-metadata pipeline, so the Grafana dashboard's
# {job=...} filter and Tempo's tracesToLogs correlation are unaffected.
#
# The Alloy config below is a faithful port of the effective promtail config
# (chart defaults + our overrides), generated with
# `alloy convert --source-format=promtail` (v1.21.2, matching the chart's
# appVersion) and reviewed; provenance notes are in its header comment.
#
# The config lives in a hand-managed kubernetes_config_map (not
# alloy.configMap.content) because the chart renders `content` through helm
# `tpl`, and the traceId stage.template contains Go-template syntax
# ({{ if .trace_id }}) that tpl would silently rewrite.

resource "kubernetes_config_map" "alloy_config" {
  metadata {
    name      = "alloy"
    namespace = kubernetes_namespace.loki.metadata[0].name
  }

  data = {
    "config.alloy" = <<-EOF
// Grafana Alloy — the cluster's log collector, replacing Promtail (EOL
// 2026-03-02). Faithful port of the effective promtail config, generated with
// `alloy convert --source-format=promtail` (v1.21.2) and reviewed.
//
// Deliberate deviations from the raw converter output:
//   - legacy_positions_file dropped: promtail's /run/promtail positions file is
//     not mounted; the one-time cutover gap (seconds of in-flight lines) was
//     accepted. Alloy's own positions live under --storage.path, which the helm
//     chart backs with a hostPath so they survive restarts.
//   - loki.write creds come from sys.env() (chart extraEnv -> secretKeyRef)
//     rather than being inlined: this config lives in a ConfigMap, not a Secret.

// Only discover pods scheduled on the local node (daemonset deployment); the
// helm chart injects HOSTNAME from spec.nodeName via fieldRef.
discovery.kubernetes "kubernetes_pods" {
  role = "pod"

  selectors {
    role  = "pod"
    field = "spec.nodeName=" + coalesce(sys.env("HOSTNAME"), constants.hostname)
  }
}

// Port of the promtail chart's default relabel_configs: emits the same stream
// labels promtail did (app, instance, component, node_name, namespace,
// job = <namespace>/<app>, pod, container), so the Grafana dashboard's
// {job="$app"} filter and Tempo's tracesToLogs correlation (namespace, pod)
// keep working unchanged.
discovery.relabel "kubernetes_pods" {
  targets = discovery.kubernetes.kubernetes_pods.targets

  // app: app.kubernetes.io/name label, else app label, else controller
  // name, else pod name.
  rule {
    source_labels = ["__meta_kubernetes_pod_controller_name"]
    regex         = "([0-9a-z-.]+?)(-[0-9a-f]{8,10})?"
    target_label  = "__tmp_controller_name"
  }

  rule {
    source_labels = ["__meta_kubernetes_pod_label_app_kubernetes_io_name", "__meta_kubernetes_pod_label_app", "__tmp_controller_name", "__meta_kubernetes_pod_name"]
    regex         = "^;*([^;]+)(;.*)?$"
    target_label  = "app"
  }

  rule {
    source_labels = ["__meta_kubernetes_pod_label_app_kubernetes_io_instance", "__meta_kubernetes_pod_label_instance"]
    regex         = "^;*([^;]+)(;.*)?$"
    target_label  = "instance"
  }

  rule {
    source_labels = ["__meta_kubernetes_pod_label_app_kubernetes_io_component", "__meta_kubernetes_pod_label_component"]
    regex         = "^;*([^;]+)(;.*)?$"
    target_label  = "component"
  }

  rule {
    source_labels = ["__meta_kubernetes_pod_node_name"]
    target_label  = "node_name"
  }

  rule {
    source_labels = ["__meta_kubernetes_namespace"]
    target_label  = "namespace"
  }

  rule {
    source_labels = ["namespace", "app"]
    separator     = "/"
    target_label  = "job"
  }

  rule {
    source_labels = ["__meta_kubernetes_pod_name"]
    target_label  = "pod"
  }

  rule {
    source_labels = ["__meta_kubernetes_pod_container_name"]
    target_label  = "container"
  }

  rule {
    source_labels = ["__meta_kubernetes_pod_uid", "__meta_kubernetes_pod_container_name"]
    separator     = "/"
    target_label  = "__path__"
    replacement   = "/var/log/pods/*$1/*.log"
  }

  // Legacy pods whose log directory name is derived from the
  // kubernetes.io/config.hash annotation instead of the pod UID (promtail
  // chart default; no-op for modern pods).
  rule {
    source_labels = ["__meta_kubernetes_pod_annotationpresent_kubernetes_io_config_hash", "__meta_kubernetes_pod_annotation_kubernetes_io_config_hash", "__meta_kubernetes_pod_container_name"]
    separator     = "/"
    regex         = "true/(.*)"
    target_label  = "__path__"
    replacement   = "/var/log/pods/*$1/*.log"
  }
}

loki.source.file "kubernetes_pods" {
  targets    = discovery.relabel.kubernetes_pods.output
  forward_to = [loki.process.kubernetes_pods.receiver]

  // Start at EOF for files with no stored position (tail_from_end defaults to
  // false, which made first boot replay months of historical pod logs that
  // Loki's reject_old_samples then 400'd, dropping whole batches).  Positions
  // persist under --storage.path, so restarts still resume mid-file.
  tail_from_end = true

  // Tail the files resolved from each target's __path__ label.
  file_match {
    enabled = true
  }
}

// Extract traceId from JSON logs into Loki structured metadata (Loki 3.x) so
// Tempo's tracesToLogs correlation can match.  Ported verbatim from the old
// promtail pipelineStages.  Stages are a no-op for log lines that carry no
// trace id: the json stage sets nothing for non-JSON lines (drop_mismatched
// defaults to false, so the pipeline continues), and the template stage yields
// an empty string when none of the keys are set, which structured_metadata
// omits.  Supported key variants: trace_id (OTEL SDK default / Traefik),
// traceId (Quarkus/Keycloak kv logs, via the regex stage), traceID (some Go
// libs); normalised into a single `traceId` metadata key.
//
// The regex stage handles non-JSON kv-format logs (e.g. Keycloak's
// `... traceId=<hex> parentId=... spanId=...` lines that the json stage can't
// parse); it is a no-op for JSON lines (which contain `traceId":` not `traceId=`)
// and for lines without a traceId.
//
// IMPORTANT: the template uses if/else (not concatenation) so that unset keys
// yield an empty string rather than Go-template's literal "<no value>" — which
// would otherwise be stored as the traceId value and break exact-match queries.
loki.process "kubernetes_pods" {
  forward_to = [loki.write.loki.receiver]

  stage.cri { }

  stage.json {
    expressions = {
      trace_id = "trace_id",
      traceId  = "traceId",
      traceID  = "traceID",
    }
  }

  stage.regex {
    expression = "traceId=(?P<traceId>[0-9a-fA-F]+)"
  }

  stage.template {
    source   = "traceId"
    template = "{{ if .trace_id }}{{ .trace_id }}{{ else if .traceId }}{{ .traceId }}{{ else if .traceID }}{{ .traceID }}{{ end }}"
  }

  stage.structured_metadata {
    values = {
      traceId = null,
    }
  }
}

loki.write "loki" {
  endpoint {
    url = "http://loki-gateway/loki/api/v1/push"

    basic_auth {
      username = sys.env("LOKI_GATEWAY_USERNAME")
      password = sys.env("LOKI_GATEWAY_PASSWORD")
    }
  }
}
    EOF
  }
}

# Loki gateway basic-auth creds for loki.write.  Injected into the Alloy pod as
# environment variables (chart extraEnv -> secretKeyRef) and read in the config
# via sys.env(), keeping secrets out of the ConfigMap.  Same random_password
# resources the promtail release used.
resource "kubernetes_secret" "loki_gateway_alloy_creds" {
  metadata {
    name      = "loki-gateway-alloy-creds"
    namespace = kubernetes_namespace.loki.metadata[0].name
  }

  data = {
    username = random_password.loki_gateway_username.result
    password = random_password.loki_gateway_password.result
  }
}

resource "helm_release" "alloy" {
  name = "alloy"

  repository = "https://grafana.github.io/helm-charts"
  chart      = "alloy"
  version    = "1.14.3"

  namespace = kubernetes_namespace.loki.metadata[0].name

  timeout = 300

  values = [
    <<-EOF
      # The crds subchart only installs the Grafana PodLogs CRD (for
      # loki.source.podlogs), which this config does not use; the cluster's
      # ServiceMonitor CRD is owned by prometheus-operator.
      crds:
        create: false

      controller:
        type: daemonset
        volumes:
          extra:
            # loki.source.file tail positions live under --storage.path; back
            # them with a hostPath so restarts resume where they left off (the
            # chart default /tmp/alloy is container-local and ephemeral).
            - name: data
              hostPath:
                path: /var/lib/alloy
                type: DirectoryOrCreate

      alloy:
        storagePath: /var/lib/alloy

        configMap:
          create: false
          name: ${kubernetes_config_map.alloy_config.metadata[0].name}
          key: config.alloy

        mounts:
          # Host /var/log (readOnly) — covers /var/log/pods container logs.
          varlog: true
          extra:
            - name: data
              mountPath: /var/lib/alloy

        extraEnv:
          - name: LOKI_GATEWAY_USERNAME
            valueFrom:
              secretKeyRef:
                name: ${kubernetes_secret.loki_gateway_alloy_creds.metadata[0].name}
                key: username
          - name: LOKI_GATEWAY_PASSWORD
            valueFrom:
              secretKeyRef:
                name: ${kubernetes_secret.loki_gateway_alloy_creds.metadata[0].name}
                key: password

      serviceMonitor:
        enabled: true
    EOF
  ]

  depends_on = [
    kubernetes_config_map.alloy_config,
    kubernetes_secret.loki_gateway_alloy_creds,
  ]
}
