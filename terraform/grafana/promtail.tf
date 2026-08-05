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
  # replaces the list.  Stages are a no-op for log lines that are not valid JSON
  # or that carry no trace id: the json stage bails (pipeline stops, line is still
  # shipped) or the extracted values are empty (structured_metadata omits empties).
  # Supported key variants: trace_id (OTEL SDK default), traceId (Quarkus/Java),
  # traceID (some Go libs); normalised into a single `traceId` metadata key.
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
            - template:
                source: traceId
                template: '{{ .trace_id }}{{ .traceId }}{{ .traceID }}'
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
