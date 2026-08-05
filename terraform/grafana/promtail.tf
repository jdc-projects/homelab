resource "helm_release" "promtail" {
  name = "promtail"

  repository = "https://grafana.github.io/helm-charts"
  chart      = "promtail"
  version    = "6.17.1"

  namespace = kubernetes_namespace.loki.metadata[0].name

  timeout = 300

  set = [
    {
      name  = "defaultVolumes[0].name"
      value = "run"
    },
    {
      name  = "defaultVolumes[0].hostPath.path"
      value = "/run/promtail"
    },
    {
      name  = "defaultVolumes[1].name"
      value = "pods"
    },
    {
      name  = "defaultVolumes[1].hostPath.path"
      value = "/var/log/pods"
    },
    {
      name  = "defaultVolumes[2].name"
      value = "mnt"
    },
    {
      name  = "defaultVolumes[2].hostPath.path"
      value = "/mnt"
    },
    {
      name  = "defaultVolumeMounts[0].name"
      value = "run"
    },
    {
      name  = "defaultVolumeMounts[0].mountPath"
      value = "/run/promtail"
    },
    {
      name  = "defaultVolumeMounts[1].name"
      value = "pods"
    },
    {
      name  = "defaultVolumeMounts[1].mountPath"
      value = "/var/log/pods"
    },
    {
      name  = "defaultVolumeMounts[1].readOnly"
      value = "true"
    },
    {
      name  = "defaultVolumeMounts[2].name"
      value = "mnt"
    },
    {
      name  = "defaultVolumeMounts[2].mountPath"
      value = "/mnt"
    },
    {
      name  = "defaultVolumeMounts[2].readOnly"
      value = "true"
    },
    {
      name  = "config.logLevel"
      value = "info"
    },
    {
      name  = "config.logFormat"
      value = "json"
    },
    {
      name  = "config.clients[0].url"
      value = "http://${helm_release.loki.name}-gateway/loki/api/v1/push"
    },
    {
      name  = "serviceMonitor.enabled"
      value = "true"
    },
  ]

  # Extract traceId from JSON logs into Loki structured metadata (Loki 3.x) so
  # Tempo's tracesToLogs correlation can match.  The default pipeline ships only
  # a `cri` stage, so we must redeclare it here — overriding snippets.pipelineStages
  # replaces the list.  Stages are a no-op for log lines that carry no trace id:
  # the json stage sets nothing for non-JSON lines (drop_mismatched defaults to
  # false, so the pipeline continues), and the template stage yields an empty
  # string when none of the keys are set, which structured_metadata omits.
  # Supported key variants: trace_id (OTEL SDK default / Traefik), traceId
  # (Quarkus/Keycloak kv logs, via the regex stage), traceID (some Go libs);
  # normalised into a single `traceId` metadata key.
  #
  # The regex stage handles non-JSON kv-format logs (e.g. Keycloak's
  # `... traceId=<hex> parentId=... spanId=...` lines that the json stage can't
  # parse); it is a no-op for JSON lines (which contain `traceId":` not `traceId=`)
  # and for lines without a traceId.
  #
  # IMPORTANT: the template uses if/else (not concatenation) so that unset keys
  # yield an empty string rather than Go-template's literal "<no value>" — which
  # would otherwise be stored as the traceId value and break exact-match queries.
  values = [
    <<-EOF
      config:
        snippets:
          pipelineStages:
            - cri: {}
            - json:
                expressions:
                  trace_id: trace_id
                  traceId: traceId
                  traceID: traceID
            - regex:
                expression: 'traceId=(?P<traceId>[0-9a-fA-F]+)'
            - template:
                source: traceId
                template: '{{ if .trace_id }}{{ .trace_id }}{{ else if .traceId }}{{ .traceId }}{{ else if .traceID }}{{ .traceID }}{{ end }}'
            - structured_metadata:
                traceId:
    EOF
  ]

  set_sensitive = [
    {
      name  = "config.clients[0].basic_auth.username"
      value = random_password.loki_gateway_username.result
    },
    {
      name  = "config.clients[0].basic_auth.password"
      value = random_password.loki_gateway_password.result
    }
  ]
}
