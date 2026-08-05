# ServiceMonitor + RBAC for KubeVirt component metrics.
#
# Discovery (live cluster, kubevirt ns):
#   svc/kubevirt-prometheus-metrics  ClusterIP=None  443->metrics(8443)
#     selector: prometheus.kubevirt.io=true   (matches virt-api/-controller/
#     -handler/-operator pods - all 6 endpoints on :8443)
#   svc/virt-api                      ClusterIP      443->8443
#   svc/virt-exportproxy             ClusterIP      443->8443
#   svc/kubevirt-operator-webhook    ClusterIP      443->webhooks(8444)
#
# Each virt-* pod exposes /metrics on its "metrics" container port (:8443)
# over HTTPS with a self-signed cert. The endpoint is auth-gated: KubeVirt
# delegates authorization to the kube-apiserver via SubjectAccessReview
# against the caller's bearer token, requiring the SA to have "get" on the
# virtualmachineinstances/metrics subresource (subresources.kubevirt.io).
# Without that grant, scrapes return 401/403 and the targets stay DOWN.
#
# So we (a) bind the Prometheus SA to a ClusterRole granting that permission,
# and (b) create a ServiceMonitor that scrapes the existing headless
# kubevirt-prometheus-metrics Service with scheme=https + bearerTokenFile +
# insecureSkipVerify. No new Service is needed - KubeVirt already ships the
# right one. (ServiceMonitor supports bearerTokenFile directly; only the
# ScrapeConfig CRD requires Secret-based auth - see prometheus/scrapeconfigs.tf.)
#
# Mirrors the kubernetes_manifest style used by prometheus/scrapeconfigs.tf
# and the kafka-operator / vaultwarden ServiceMonitors.

locals {
  kubevirt_namespace         = "kubevirt"
  prometheus_namespace       = "prometheus"
  prometheus_service_account = "kube-prometheus-stack-prometheus"
}

# ClusterRole permitting the bearer (the Prometheus SA) to read the
# virtualmachineinstances/metrics subresource that KubeVirt's auth-delegation
# webhook checks before serving /metrics on each virt-* pod. KubeVirt ships
# no pre-existing "kubevirt-metrics" role in this cluster, so we own one.
resource "kubernetes_manifest" "kubevirt_metrics_clusterrole" {
  manifest = {
    apiVersion = "rbac.authorization.k8s.io/v1"
    kind       = "ClusterRole"

    metadata = {
      name = "kubevirt-metrics-reader"
    }

    rules = [
      {
        apiGroups = ["subresources.kubevirt.io"]
        resources = ["virtualmachineinstances/metrics"]
        verbs     = ["get", "list"]
      },
    ]
  }
}

resource "kubernetes_manifest" "kubevirt_metrics_clusterrolebinding" {
  manifest = {
    apiVersion = "rbac.authorization.k8s.io/v1"
    kind       = "ClusterRoleBinding"

    metadata = {
      name = "kubevirt-metrics-reader"
    }

    roleRef = {
      apiGroup = "rbac.authorization.k8s.io"
      kind     = "ClusterRole"
      name     = "kubevirt-metrics-reader"
    }

    subjects = [
      {
        kind      = "ServiceAccount"
        name      = local.prometheus_service_account
        namespace = local.prometheus_namespace
      },
    ]
  }

  depends_on = [kubernetes_manifest.kubevirt_metrics_clusterrole]
}

# Scrapes every virt-* pod via the headless kubevirt-prometheus-metrics
# Service (selector prometheus.kubevirt.io=true). Targets appear as
# kubevirt/kubevirt-components/0..N in Prometheus.
resource "kubernetes_manifest" "kubevirt_servicemonitor" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"

    metadata = {
      name      = "kubevirt-components"
      namespace = local.kubevirt_namespace

      labels = {
        "prometheus.kubevirt.io" = "true"
      }
    }

    spec = {
      # Select the existing headless Service created by the KubeVirt operator.
      selector = {
        matchLabels = {
          "prometheus.kubevirt.io" = "true"
        }
      }

      # Target Services live in the kubevirt ns. ServiceMonitor is also in
      # kubevirt, so this matches the CRD default - kept explicit for clarity.
      namespaceSelector = {
        matchNames = [local.kubevirt_namespace]
      }

      endpoints = [
        {
          port            = "metrics"
          path            = "/metrics"
          scheme          = "https"
          interval        = "60s"
          scrapeTimeout   = "30s"
          bearerTokenFile = "/var/run/secrets/kubernetes.io/serviceaccount/token"

          tlsConfig = {
            insecureSkipVerify = true
          }
        },
      ]
    }
  }

  depends_on = [kubernetes_manifest.kubevirt_metrics_clusterrolebinding]
}
