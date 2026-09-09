# https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack
#
# Installs the Prometheus instance, Alertmanager, node-exporter and
# kube-state-metrics. The operator + CRDs are in iac/prometheus-operator/.
#
# This release provides INFRASTRUCTURE ONLY - no rules or dashboards. Those
# are managed separately:
#   - PrometheusRules: iac/prometheus/rules/ (via prometheusrules.tf)
#   - Grafana dashboards: iac/prometheus/dashboards/ (via grafana-dashboards.tf)
#
# On K3s the control plane components (apiserver, controller-manager, scheduler,
# kube-proxy) are bundled into one process. Their metrics are collected via
# custom ScrapeConfigs in scrapeconfigs.tf, not the chart's ServiceMonitors.
# All chart-provided cluster-component monitors are disabled.

locals {
  # Size of the Prometheus TSDB PVC (Gi). retentionSize is derived from this so
  # the byte cap always tracks the volume: if the PVC is ever resized, both
  # values move together. At ~0.7GiB/day ingestion, 30d retention needs ~21GiB
  # of blocks, plus WAL/compaction headroom - 60Gi leaves ~2x margin.
  prometheus_db_storage_gib = 60
}

resource "helm_release" "kube_prometheus_stack" {
  name = "kube-prometheus-stack"

  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = data.terraform_remote_state.prometheus_operator.outputs.kube_prometheus_stack_version

  namespace = kubernetes_namespace.prometheus.metadata[0].name

  timeout = 600

  skip_crds = true

  set = [
    # Operator + CRDs owned by iac/prometheus-operator/.
    {
      name  = "prometheusOperator.enabled"
      value = "false"
    },
    # Instance + exporters.
    {
      name  = "prometheus.enabled"
      value = "true"
    },
    {
      name  = "alertmanager.enabled"
      value = "true"
    },
    {
      name  = "nodeExporter.enabled"
      value = "true"
    },
    {
      name  = "kubeStateMetrics.enabled"
      value = "true"
    },
    # Rules and dashboards are managed in OpenTofu, not by the chart.
    {
      name  = "defaultRules.create"
      value = "false"
    },
    {
      name  = "grafana.enabled"
      value = "false"
    },
    {
      name  = "grafana.forceDeployDashboards"
      value = "false"
    },
    # All cluster-component monitors disabled - ScrapeConfigs in
    # scrapeconfigs.tf handle kubelet, etcd and coredns.
    {
      name  = "kubeApiServer.enabled"
      value = "false"
    },
    {
      name  = "kubelet.enabled"
      value = "false"
    },
    {
      name  = "kubeControllerManager.enabled"
      value = "false"
    },
    {
      name  = "coreDns.enabled"
      value = "false"
    },
    {
      name  = "kubeEtcd.enabled"
      value = "false"
    },
    {
      name  = "kubeScheduler.enabled"
      value = "false"
    },
    {
      name  = "kubeProxy.enabled"
      value = "false"
    },
    # Discover ServiceMonitors/PodMonitors/Rules/ScrapeConfigs cluster-wide.
    {
      name  = "prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues"
      value = "false"
    },
    {
      name  = "prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues"
      value = "false"
    },
    {
      name  = "prometheus.prometheusSpec.ruleSelectorNilUsesHelmValues"
      value = "false"
    },
    {
      name  = "prometheus.prometheusSpec.probeSelectorNilUsesHelmValues"
      value = "false"
    },
    {
      name  = "prometheus.prometheusSpec.scrapeConfigSelectorNilUsesHelmValues"
      value = "false"
    },
    # Retention.
    {
      name  = "prometheus.prometheusSpec.retention"
      value = "30d"
    },
    # Enable the remote-write receiver so the OTel collector can push
    # OTLP-sourced metrics via its prometheusremotewrite exporter.
    {
      name  = "prometheus.prometheusSpec.enableRemoteWriteReceiver"
      value = "true"
    },
    # Storage class mirrors iac/grafana/loki.tf.
    {
      name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.storageClassName"
      value = "openebs-zfs-localpv-random-no-backup"
    },
    {
      name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.accessModes[0]"
      value = "ReadWriteOnce"
    },
    {
      name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage"
      value = "${local.prometheus_db_storage_gib}Gi"
    },
    # Hard byte cap on the TSDB dir, kept 1Gi under the PVC: Prometheus drops
    # oldest blocks before the disk can fill, trading retention for uptime
    # instead of deadlocking on a full WAL (which took monitoring down for
    # ~10h on 2026-09-09).
    {
      name  = "prometheus.prometheusSpec.retentionSize"
      value = "${local.prometheus_db_storage_gib - 1}GiB"
    },
    # Alertmanager storage (small - only stores silences + notification state).
    {
      name  = "alertmanager.alertmanagerSpec.storage.volumeClaimTemplate.spec.storageClassName"
      value = "openebs-zfs-localpv-random-no-backup"
    },
    {
      name  = "alertmanager.alertmanagerSpec.storage.volumeClaimTemplate.spec.accessModes[0]"
      value = "ReadWriteOnce"
    },
    {
      name  = "alertmanager.alertmanagerSpec.storage.volumeClaimTemplate.spec.resources.requests.storage"
      value = "5Gi"
    },
  ]

  # Alertmanager config: SMTP email receiver for warning+ alerts. InfoInhibitor
  # (severity=none) is routed to a null receiver to prevent email noise from
  # internal framework alerts. Curated rules in prometheusrules.tf provide the
  # alert definitions.
  values = [
    <<-EOF
      alertmanager:
        config:
          global:
            smtp_smarthost: "${var.smtp_host}:${var.smtp_port}"
            smtp_from: "alertmanager@${var.server_base_domain}"
            smtp_auth_username: "${var.smtp_username}"
            smtp_auth_password: "${var.smtp_password}"
            resolve_timeout: 5m
          inhibit_rules:
            - source_matchers:
                - 'severity = critical'
              target_matchers:
                - 'severity =~ warning|info'
              equal:
                - 'namespace'
                - 'alertname'
            - source_matchers:
                - 'severity = warning'
              target_matchers:
                - 'severity = info'
              equal:
                - 'namespace'
                - 'alertname'
            - source_matchers:
                - 'alertname = InfoInhibitor'
              target_matchers:
                - 'severity = info'
              equal:
                - 'namespace'
          route:
            group_by: ['namespace']
            group_wait: 30s
            group_interval: 5m
            repeat_interval: 12h
            receiver: 'email'
            routes:
              # Watchdog always emails (confirms Alertmanager is working)
              - receiver: 'email'
                matchers:
                  - alertname = "Watchdog"
              # Drop framework alerts with no actionable severity
              # (InfoInhibitor, etc.)
              - receiver: 'null'
                matchers:
                  - severity = "none"
          receivers:
            - name: 'null'
            - name: 'email'
              email_configs:
                - to: "${var.admin_email}"
                  send_resolved: true
          templates:
            - '/etc/alertmanager/config/*.tmpl'
    EOF
  ]
}
