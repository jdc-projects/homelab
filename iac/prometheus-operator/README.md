# prometheus-operator

Installs the Prometheus operator (kube-prometheus-stack chart, operator-only).

The companion Prometheus instance, Alertmanager, node-exporter, kube-state-metrics
and default alert/monitoring rules live in `iac/prometheus/`.

The chart version is exposed as a Terraform output and consumed by
`iac/prometheus/` via `terraform_remote_state` so both modules always
pin to the same chart release - required because the CRDs installed here must
match what the instance module templates against.
