# https://github.com/elastic/cloud-on-k8s (ECK — Elastic Cloud on Kubernetes)
#
# Huly pins the @elastic/elasticsearch JS client to ^7.17.14, so we run
# ES 7.17.x for it. ECK 3.3.0 (PR #9038) removed 7.17 from the docs/test
# matrix but the actual code-level version gate in
# pkg/controller/elasticsearch/version/supported_versions.go still accepts
# 7.0.0-7.99.99 — applying an Elasticsearch CR with spec.version: 7.17.x
# succeeds and prints a non-blocking "EOL" admission warning. We accept that
# warning as harmless noise and stay on the current ECK line for security
# fixes and active development. Chart version is pinned so a future bump
# can't silently pull a release that finally drops the `case 7` branch.
#
# Cluster-scoped (the chart default): a single operator reconciles
# `Elasticsearch` CRs in any namespace, matching how the opensearch-operator
# and kafka-operator modules are wired.

resource "helm_release" "elastic_operator" {
  name      = "elastic-operator"
  namespace = kubernetes_namespace.elasticsearch_operator.metadata[0].name

  repository = "https://helm.elastic.co"
  chart      = "eck-operator"
  version    = "3.5.0"

  timeout = 300
}
