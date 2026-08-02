# prometheus

Installs the Prometheus instance, Alertmanager, node-exporter and
kube-state-metrics via kube-prometheus-stack (infrastructure only).

The operator + CRDs are in `terraform/prometheus-operator/`. This release
uses `skip_crds = true` and reads the chart version from the operator module
via `terraform_remote_state` so both stay in lock-step.

## Architecture

The chart provides **infrastructure only** — no rules or dashboards:

- **PrometheusRules**: curated in `rules/` (26 files extracted from
  kube-prometheus-stack, same version as pinned in the operator module).
  The 9 per-component rule files that are K3s false positives (apiserver,
  controller-manager, scheduler, proxy) are excluded. Deployed via
  `prometheusrules.tf`.

- **Grafana dashboards**: curated in `dashboards/` (JSON files from the
  same chart version). Component-specific dashboards (apiserver,
  controller-manager, scheduler, proxy) have K3s job label fixes applied.
  Irrelevant dashboards (AIX, Darwin, multicluster) are excluded.
  Deployed via `grafana-dashboards.tf`.

- **ScrapeConfigs**: custom K3s-specific configs in `scrapeconfigs.tf`
  (kubelet, etcd, coredns). No resources created in `kube-system`.

- **Grafana datasource**: Prometheus datasource in `grafana-datasource.tf`,
  set as default.

## K3s cluster monitoring

K3s bundles `kube-apiserver`, `kube-controller-manager`, `kube-scheduler`
and `kube-proxy` into a single process with kubelet. Their metrics are all
exposed via the kubelet endpoint — scraping kubelet on `:10250/metrics`
returns the combined control plane metrics stream. No separate targets exist
for the other components.

The one exception is **etcd** — a separate process scraped on `:2381`
(requires `etcd-expose-metrics: true` in the K3s config, see `k3s/k3s.tf`).

## Updating rules and dashboards

Both are pinned to the chart version defined in
`terraform/prometheus-operator/prometheus-operator.tf`. To update:

```bash
# Render the chart
helm template kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --version <NEW_VERSION> --set prometheusOperator.enabled=false \
  --set grafana.enabled=false --set defaultRules.create=true \
  --set kubeApiServer.enabled=true --set kubelet.enabled=true \
  --set kubeControllerManager.enabled=true --set coreDns.enabled=true \
  --set kubeEtcd.enabled=true --set kubeScheduler.enabled=true \
  --set kubeProxy.enabled=true

# Extract PrometheusRules (skip K3s-incompatible files)
# Extract dashboard JSONs from ConfigMaps (skip component-specific ones)
# Diff against existing files in rules/ and dashboards/
```

Also update the chart version in `terraform/prometheus-operator/prometheus-operator.tf`.
