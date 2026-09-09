# ScrapeConfig resources for K3s-specific monitoring.
#
# K3s bundles kube-apiserver, kube-controller-manager, kube-scheduler and
# kube-proxy into a single process with kubelet. Their metrics are all
# exposed via the kubelet endpoint (/metrics), so we scrape kubelet only -
# no separate targets for the other components (they'd just duplicate).
#
# The one exception is etcd, which runs as a separate process and must be
# scraped independently on :2381 (plaintext HTTP, enabled via the
# etcd-expose-metrics flag in k3s/k3s.tf).
#
# All discovery uses kubernetesSDConfigs (node/pod roles) - no Services or
# Endpoints are created in kube-system. This keeps the blast radius entirely
# within the prometheus namespace.
#
# Note: the ScrapeConfig CRD requires Secret-based auth (no bearerTokenFile),
# unlike ServiceMonitor. We create a service-account-token Secret for the
# Prometheus SA and reference it.

locals {
  # kubelet exposes 4 metric paths, each with a different set of series.
  # We create one ScrapeConfig per path so they show up as separate jobs.
  kubelet_scrape_paths = {
    kubelet  = "/metrics"
    cadvisor = "/metrics/cadvisor"
    resource = "/metrics/resource"
    probes   = "/metrics/probes"
  }
}

# Secret containing a long-lived token for the Prometheus service account.
# The ScrapeConfig CRD requires Secret-based auth (no bearerTokenFile field),
# so we create this to provide the bearer token for kubelet scraping.
# Kubernetes auto-populates the token data field asynchronously after creation.
resource "kubernetes_secret" "prometheus_scrape_token" {
  metadata {
    name      = "prometheus-scrape-token"
    namespace = kubernetes_namespace.prometheus.metadata[0].name

    annotations = {
      "kubernetes.io/service-account.name" = "${helm_release.kube_prometheus_stack.name}-prometheus"
    }
  }

  type = "kubernetes.io/service-account-token"

  # Ensure the Prometheus SA exists before creating this Secret.
  depends_on = [helm_release.kube_prometheus_stack]
}

# kubelet - captures the combined control plane metrics stream on K3s
# (apiserver + controller-manager + scheduler + proxy + kubelet in one scrape).
resource "kubernetes_manifest" "kubelet_scrape" {
  for_each = local.kubelet_scrape_paths

  manifest = {
    apiVersion = "monitoring.coreos.com/v1alpha1"
    kind       = "ScrapeConfig"

    metadata = {
      name      = "kubelet-${each.key}"
      namespace = kubernetes_namespace.prometheus.metadata[0].name
    }

    # The spec is merged so metricRelabelings exists only on the cadvisor
    # entry: the CRD rejects an empty list, and an explicit null leaves
    # kubernetes_manifest planning a perpetual diff.
    spec = merge(
      {
        jobName = "kubelet"

        metricsPath = each.value

        scheme = "HTTPS"

        tlsConfig = {
          insecureSkipVerify = true
        }

        authorization = {
          type = "Bearer"
          credentials = {
            name = kubernetes_secret.prometheus_scrape_token.metadata[0].name
            key  = "token"
          }
        }

        kubernetesSDConfigs = [
          {
            role = "Node"
          }
        ]

        relabelings = [
          {
            sourceLabels = ["__meta_kubernetes_node_name"]
            targetLabel  = "node"
          },
          {
            sourceLabels = ["__meta_kubernetes_node_address_InternalIP"]
            targetLabel  = "__address__"
            regex        = "(.+)"
            replacement  = "$1:10250"
            action       = "replace"
          },
          # Expose the metrics path as a visible label. The chart's dashboards
          # and alert rules filter on metrics_path="/metrics" etc. Without this
          # relabel, __metrics_path__ stays internal and those queries return
          # empty ("No Data" on dashboards, false-positive KubeletDown alert).
          {
            sourceLabels = ["__metrics_path__"]
            targetLabel  = "metrics_path"
            action       = "replace"
          },
        ]
      },

      # cAdvisor emits a handful of high-cardinality, near-zero-value metrics
      # (~25k series on this cluster, none referenced by any rule or dashboard
      # in this repo). Drop them at ingest to slow TSDB growth.
      each.key == "cadvisor" ? {
        metricRelabelings = [
          {
            sourceLabels = ["__name__"]
            regex        = "container_(tasks_state|blkio_device_usage_total|memory_failures_total)"
            action       = "drop"
          },
        ]
      } : {}
    )
  }

  depends_on = [kubernetes_secret.prometheus_scrape_token, helm_release.kube_prometheus_stack]
}

# etcd - the only control plane component NOT bundled into the kubelet
# metrics stream. Requires etcd-expose-metrics: true in the K3s config
# (k3s/k3s.tf). Plaintext HTTP on :2381, no TLS certs needed.
resource "kubernetes_manifest" "etcd_scrape" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1alpha1"
    kind       = "ScrapeConfig"

    metadata = {
      name      = "k3s-etcd"
      namespace = kubernetes_namespace.prometheus.metadata[0].name
    }

    spec = {
      jobName = "etcd"

      metricsPath = "/metrics"
      scheme      = "HTTP"

      kubernetesSDConfigs = [
        {
          role = "Node"
        }
      ]

      relabelings = [
        {
          sourceLabels = ["__meta_kubernetes_node_address_InternalIP"]
          targetLabel  = "__address__"
          regex        = "(.+)"
          replacement  = "$1:2381"
          action       = "replace"
        },
        {
          sourceLabels = ["__meta_kubernetes_node_name"]
          targetLabel  = "node"
        },
      ]
    }
  }

  depends_on = [helm_release.kube_prometheus_stack]
}

# coredns - DNS resolver metrics. Discovers coredns pods in kube-system
# via pod role discovery + relabel filters. No Service needed.
resource "kubernetes_manifest" "coredns_scrape" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1alpha1"
    kind       = "ScrapeConfig"

    metadata = {
      name      = "coredns"
      namespace = kubernetes_namespace.prometheus.metadata[0].name
    }

    spec = {
      jobName = "coredns"

      metricsPath = "/metrics"
      scheme      = "HTTP"

      kubernetesSDConfigs = [
        {
          role = "Pod"
        }
      ]

      relabelings = [
        {
          sourceLabels = ["__meta_kubernetes_namespace"]
          regex        = "kube-system"
          action       = "keep"
        },
        {
          sourceLabels = ["__meta_kubernetes_pod_label_k8s_app"]
          regex        = "kube-dns"
          action       = "keep"
        },
        {
          sourceLabels = ["__address__"]
          regex        = "([^:]+):.*"
          replacement  = "$1:9153"
          targetLabel  = "__address__"
          action       = "replace"
        },
        {
          sourceLabels = ["__meta_kubernetes_pod_name"]
          targetLabel  = "pod"
        },
      ]
    }
  }

  depends_on = [helm_release.kube_prometheus_stack]
}
