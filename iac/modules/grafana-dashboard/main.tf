terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}

locals {
  # grafana instance targeting contract. This is the single source of truth for
  # the label that all GrafanaDashboard CRs use to select the Grafana instance.
  # It MUST match the label on the Grafana CR in iac/grafana/grafana.tf
  # (currently { dashboards = "grafana" }).
  #
  # grafana-operator v5 also auto-assigns each dashboard to a folder named after
  # the namespace of its GrafanaDashboard CR, so dashboards created here land in
  # a folder named after var.namespace.
  instance_selector = {
    dashboards = "grafana"
  }
}

resource "kubernetes_manifest" "dashboard" {
  for_each = var.dashboards

  manifest = {
    apiVersion = "grafana.integreatly.org/v1beta1"
    kind       = "GrafanaDashboard"

    metadata = {
      name      = each.key
      namespace = var.namespace
    }

    spec = {
      allowCrossNamespaceImport = "true"

      instanceSelector = {
        matchLabels = local.instance_selector
      }

      json = each.value
    }
  }
}
