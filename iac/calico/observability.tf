# Calico metrics for Prometheus.
#
# Calico's Felix metrics are DISABLED by default. Enabling prometheusMetricsEnabled
# on the operator-managed default FelixConfiguration makes calico-node serve
# /metrics on port 9091 (the Felix default). The FelixConfiguration is owned by
# the operator, so we toggle it with an idempotent kubectl patch (not a
# kubernetes_manifest) to avoid taking ownership of the operator's resource.
# A Service + ServiceMonitor then let the cluster-wide select-all Prometheus
# scrape it.
#
# Other observability: Loki's promtail (DaemonSet in the loki namespace) already
# tails all pod logs including calico-system, so no log change is needed. Calico
# emits no traces, so Tempo is unaffected.

# Idempotent: enable Felix Prometheus metrics on the operator-managed default
# FelixConfiguration. Re-runs on Calico version bumps.
resource "null_resource" "enable_felix_metrics" {
  triggers = {
    calico_version = "v3.32.1"
  }

  provisioner "local-exec" {
    command = "kubectl --kubeconfig=${path.module}/../cluster.yml patch felixconfiguration default --type=merge -p='{\"spec\":{\"prometheusMetricsEnabled\":true}}'"
  }

  depends_on = [kubernetes_manifest.installation]
}

# Headless-ish scrape target: a Service selecting the hostNetwork calico-node
# pods, exposing Felix's metrics port under a named port for the ServiceMonitor.
resource "kubernetes_manifest" "calico_node_metrics_service" {
  manifest = {
    apiVersion = "v1"
    kind       = "Service"

    metadata = {
      name      = "calico-node-metrics"
      namespace = "calico-system"

      labels = {
        "k8s-app" = "calico-node"
      }
    }

    spec = {
      type = "ClusterIP"

      selector = {
        "k8s-app" = "calico-node"
      }

      ports = [{
        name       = "metrics"
        port       = 9091
        targetPort = 9091
      }]
    }
  }

  depends_on = [null_resource.enable_felix_metrics]
}

# Scraped by the cluster-wide select-all Prometheus (no namespace labelling
# required; see iac/prometheus/prometheus.tf).
resource "kubernetes_manifest" "calico_node_servicemonitor" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"

    metadata = {
      name      = "calico-node"
      namespace = "calico-system"

      labels = {
        "homelab.jdc/calico" = "metrics"
      }
    }

    spec = {
      namespaceSelector = {
        matchNames = ["calico-system"]
      }

      selector = {
        matchLabels = {
          "k8s-app" = "calico-node"
        }
      }

      endpoints = [{
        port     = "metrics"
        interval = "30s"
      }]
    }
  }

  depends_on = [kubernetes_manifest.calico_node_metrics_service]
}
