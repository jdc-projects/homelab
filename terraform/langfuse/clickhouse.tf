# ***** https://doc.crds.dev/github.com/Altinity/clickhouse-operator/clickhouse.altinity.com/ClickHouseInstallation/v1@release-0.20.0
resource "kubectl_manifest" "clickhouse_installation" {
  yaml_body = yaml_encode({
    apiVersion = ""
    kind = ""

    metadata = {
      name = ""
      namespace = ""
    }

    spec = {
      configuration = {

      }

      templates = {

      }
    }
  })
}
