# https://github.com/opensearch-project/opensearch-k8s-operator

resource "helm_release" "opensearch_operator" {
  name      = "opensearch-operator"
  namespace = kubernetes_namespace.opensearch_operator.metadata[0].name

  repository = "https://opensearch-project.github.io/opensearch-k8s-operator/"
  chart      = "opensearch-operator"
  version    = "3.0.2"

  # v3.0.x exposes the manager's metrics bind address as a value (previously
  # hardcoded to 127.0.0.1:8080, which made /metrics unreachable from outside
  # the pod). Bind to 0.0.0.0 so the opensearch-operator-metrics Service can
  # route to it. v3 also drops kube-rbac-proxy; metrics auth is now handled by
  # controller-runtime (TokenReview + SubjectAccessReview), authorized via the
  # prometheus SA's existing get-on-/metrics ClusterRole.
  set = [
    {
      name  = "manager.metricsBindAddress"
      value = "0.0.0.0:8080"
    },
    # Render the chart's crds.yaml template (charts/*/files/*.yaml, BOTH the
    # opensearch.org/v1 and opensearch.opster.io/v1 groups) so helm OWNS all
    # 20 CRDs. The v3 operator's clustermigration controller hard-requires
    # the legacy opster.io CRDs to exist - deleted (not just empty), the
    # operator crashloops on "failed to wait for clustermigration caches to
    # sync" within ~2m of every start, up in 2-minute windows, which is how
    # its bootstrap-pod lifecycle went erratic mid-formation. Without this
    # flag the CRDs are only whatever a previous install happened to leave
    # behind (2.8.4-era, unmanaged, silently deleted in the 2026-08-29
    # cleanup attempt - restored from the chart's files/ on 2026-08-30).
    {
      name  = "installCRDs"
      value = "true"
    },
  ]

  timeout = 300
}
