# https://github.com/Altinity/clickhouse-operator/tree/master/deploy/helm/clickhouse-operator
#
# NOTE: any ClickHouseInstallation must use the compat image
# (ghcr.io/jdc-projects/clickhouse-compat), not the official one - see README.md.

resource "null_resource" "clickhouse_operator_crds" {
  triggers = {
    version = "0.27.1"
  }

  provisioner "local-exec" {
    when    = create
    command = <<-EOF
      kubectl apply -f https://raw.githubusercontent.com/Altinity/clickhouse-operator/release-${self.triggers.version}/deploy/helm/clickhouse-operator/crds/CustomResourceDefinition-clickhouseinstallations.clickhouse.altinity.com.yaml
      kubectl apply -f https://raw.githubusercontent.com/Altinity/clickhouse-operator/release-${self.triggers.version}/deploy/helm/clickhouse-operator/crds/CustomResourceDefinition-clickhouseinstallationtemplates.clickhouse.altinity.com.yaml
      kubectl apply -f https://raw.githubusercontent.com/Altinity/clickhouse-operator/release-${self.triggers.version}/deploy/helm/clickhouse-operator/crds/CustomResourceDefinition-clickhouseoperatorconfigurations.clickhouse.altinity.com.yaml
      kubectl apply -f https://raw.githubusercontent.com/Altinity/clickhouse-operator/release-${self.triggers.version}/deploy/helm/clickhouse-operator/crds/CustomResourceDefinition-clickhousekeeperinstallations.clickhouse-keeper.altinity.com.yaml
    EOF
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOF
      kubectl delete -f https://raw.githubusercontent.com/Altinity/clickhouse-operator/release-${self.triggers.version}/deploy/helm/clickhouse-operator/crds/CustomResourceDefinition-clickhouseinstallations.clickhouse.altinity.com.yaml
      kubectl delete -f https://raw.githubusercontent.com/Altinity/clickhouse-operator/release-${self.triggers.version}/deploy/helm/clickhouse-operator/crds/CustomResourceDefinition-clickhouseinstallationtemplates.clickhouse.altinity.com.yaml
      kubectl delete -f https://raw.githubusercontent.com/Altinity/clickhouse-operator/release-${self.triggers.version}/deploy/helm/clickhouse-operator/crds/CustomResourceDefinition-clickhouseoperatorconfigurations.clickhouse.altinity.com.yaml
      kubectl delete -f https://raw.githubusercontent.com/Altinity/clickhouse-operator/release-${self.triggers.version}/deploy/helm/clickhouse-operator/crds/CustomResourceDefinition-clickhousekeeperinstallations.clickhouse-keeper.altinity.com.yaml
    EOF
  }
}

resource "helm_release" "clickhouse_operator" {
  name      = "clickhouse-operator"
  namespace = kubernetes_namespace.clickhouse_operator.metadata[0].name

  repository = "https://docs.altinity.com/clickhouse-operator"
  chart      = "altinity-clickhouse-operator"
  version    = null_resource.clickhouse_operator_crds.triggers.version

  timeout = 300

  set = [
    {
      name  = "configs.files.config\\.yaml.watch.namespaces[0]"
      value = ".*"
    },
  ]
}
