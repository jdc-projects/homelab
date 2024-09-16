locals {
  kube_prometheus_stack_version = "61.9.0"
}

resource "null_resource" "crd_updates" {
  triggers = {
    chart_version = local.kube_prometheus_stack_version
    yq_version    = "v4.44.3"
    yq_binary     = "linux_amd64"
  }

  provisioner "local-exec" {
    when    = create
    command = <<-EOF
      sudo curl -Lo yq_${self.triggers.yq_binary}.tar.gz https://github.com/mikefarah/yq/releases/download/${self.triggers.yq_version}/yq_${self.triggers.yq_binary}.tar.gz
      sudo tar -xzf yq_${self.triggers.yq_binary}.tar.gz
      sudo mv yq_${self.triggers.yq_binary} /usr/bin/yq
      helm show chart kube-prometheus-stack --repo https://prometheus-community.github.io/helm-charts | sudo tee chart.yml
      APP_VERSION=`sudo yq -r .appVersion chart.yml` && export APP_VERSION
      sudo curl -Lo prometheus-operator.tar.gz https://github.com/prometheus-operator/prometheus-operator/archive/refs/tags/$APP_VERSION.tar.gz
      sudo mkdir ./prometheus-operator
      sudo tar -xzf prometheus-operator.tar.gz -C prometheus-operator
      cd ./prometheus-operator/*/example/prometheus-operator-crd/
      kubectl apply --server-side --force-conflicts -f ./
    EOF
  }
}

resource "helm_release" "prometheus_operator" {
  name      = "prometheus-operator"
  namespace = kubernetes_namespace.prometheus_operator.metadata[0].name

  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = local.kube_prometheus_stack_version

  timeout = 300

  set {
    name  = "grafana.enabled"
    value = "false"
  }

  set {
    name  = "prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues"
    value = "false"
  }
  set {
    name  = "prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues"
    value = "false"
  }
  set {
    name  = "prometheus.prometheusSpec.probeSelectorNilUsesHelmValues"
    value = "false"
  }

  depends_on = [
    null_resource.crd_updates,
  ]
}
