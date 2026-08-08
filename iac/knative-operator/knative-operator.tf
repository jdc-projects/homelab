# https://github.com/knative/operator/tree/v1.22.3
# Installs the Knative Operator, which owns the KnativeServing and
# KnativeEventing CRDs and reconciles the Serving/Eventing installs declared in
# iac/knative/. The operator is cluster-scoped (watches all namespaces).

resource "helm_release" "knative_operator" {
  name = "knative-operator"

  repository = "https://knative.github.io/operator"
  chart      = "knative-operator"
  version    = "v1.22.3"

  namespace = kubernetes_namespace.knative_operator.metadata[0].name

  timeout = 300
}
