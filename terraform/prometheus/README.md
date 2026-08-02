# prometheus

Installs the Prometheus instance, Alertmanager, node-exporter, kube-state-metrics
and the default alert rules / ServiceMonitors shipped by kube-prometheus-stack.

The operator itself and its CRDs live in `terraform/prometheus-operator/`.
This release uses `skip_crds = true` and reads the chart version from the
operator module via `terraform_remote_state` so both installs stay in lock-step.

Prometheus discovers ServiceMonitors/PodMonitors/ScrapeConfigs cluster-wide
(any namespace, any label) so monitors installed by other modules (e.g.
traefik) are picked up without label juggling.

Alertmanager sends notifications to `var.admin_email` via SMTP.

## K3s cluster monitoring

All chart-provided cluster-component monitors are disabled. Instead,
`scrapeconfigs.tf` creates custom `ScrapeConfig` CRDs that scrape the
cluster without creating any resources in `kube-system`:

| ScrapeConfig | Targets | Notes |
|---|---|---|
| `kubelet-*` (4 jobs) | All nodes, `:10250` | Captures the combined control plane metrics stream |
| `k3s-etcd` | All nodes, `:2381` | Requires `etcd-expose-metrics: true` in the K3s config (`k3s/k3s.tf`) |
| `coredns` | coredns pods, `:9153` | Pod-discovery via relabel filters |

### Why no separate targets for controller-manager / scheduler / proxy / apiserver?

K3s bundles `kube-apiserver`, `kube-controller-manager`, `kube-scheduler`,
and `kube-proxy` into a single process alongside `kubelet`. They share one
metrics endpoint - scraping kubelet on `:10250/metrics` already returns all
of their metrics combined. The chart's separate monitors would either find
zero matching pods (dead endpoints) or produce duplicate samples.

### etcd dependency

The etcd ScrapeConfig will show as "down" until `etcd-expose-metrics: true`
is applied to the K3s node config and K3s is restarted. The flag is set in
`k3s/k3s.tf` but requires SSH access to apply (the k3s module is a
provisioning-time tool, not in the CI deploy workflow).
