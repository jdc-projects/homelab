# https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack
#
# Installs the actual Prometheus instance, Alertmanager, node-exporter,
# kube-state-metrics and all default alert rules / ServiceMonitors shipped by
# kube-prometheus-stack. The operator itself (and the CRDs this chart's
# templates depend on) is installed by terraform/prometheus-operator/.
#
# `skip_crds = true` is critical: this release owns no CRDs, otherwise Helm
# would try to re-apply them and conflict with the operator release's hooks.

resource "helm_release" "kube_prometheus_stack" {
  name = "kube-prometheus-stack"

  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = data.terraform_remote_state.prometheus_operator.outputs.kube_prometheus_stack_version

  namespace = kubernetes_namespace.prometheus.metadata[0].name

  timeout = 600

  skip_crds = true

  set = [
    # Operator + CRDs are owned by terraform/prometheus-operator/.
    {
      name  = "prometheusOperator.enabled"
      value = "false"
    },
    # Instance + exporters + default rules.
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
    {
      name  = "defaultRules.create"
      value = "true"
    },
    {
      name  = "grafana.enabled"
      value = "false"
    },
    # All chart-provided cluster-component monitors are disabled. On K3s, the
    # control plane components (apiserver, controller-manager, scheduler,
    # kube-proxy) are bundled into one process - their metrics are already
    # captured via the kubelet ScrapeConfig in scrapeconfigs.tf. The chart's
    # separate monitors would either have zero endpoints (no matching pods)
    # or produce duplicate samples. Custom ScrapeConfigs in scrapeconfigs.tf
    # handle kubelet, etcd and coredns without creating any resources in
    # kube-system.
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
    # Discover ServiceMonitors/PodMonitors/Rules cluster-wide (any namespace,
    # any label) so monitors from other namespaces (e.g. traefik) are picked
    # up. Defaults to label-matching, which would silently drop them.
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
      value = "15d"
    },
    # Storage class mirrors terraform/grafana/loki.tf.
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
      value = "30Gi"
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

  # Alertmanager config: SMTP email receiver for all alerts. kube-prometheus-stack
  # ships ~100 default rules (node down, CPU saturation, cert expiry, etc.),
  # so wiring email here gives us working alerting out of the box.
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
              - receiver: 'email'
                matchers:
                  - alertname = "Watchdog"
          receivers:
            - name: 'email'
              email_configs:
                - to: "${var.admin_email}"
                  send_resolved: true
          templates:
            - '/etc/alertmanager/config/*.tmpl'
    EOF
  ]
}
