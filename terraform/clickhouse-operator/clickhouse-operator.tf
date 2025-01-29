resource "null_resource" "clickhouse_operator" {
  triggers = {
    always_run = timestamp()
    namespace  = "clickhouse-operator"
    version    = "release-0.24.3"
  }

  provisioner "local-exec" {
    when    = create
    command = <<-EOF
      curl -s https://raw.githubusercontent.com/Altinity/clickhouse-operator/${self.triggers.version}/deploy/operator-web-installer/clickhouse-operator-install.sh | OPERATOR_NAMESPACE=${self.triggers.namespace} METRICS_EXPORTER_NAMESPACE=${self.triggers.namespace} bash
    EOF
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOF
      curl -s https://raw.githubusercontent.com/Altinity/clickhouse-operator/${self.triggers.version}/deploy/operator-web-installer/clickhouse-operator-delete.sh | OPERATOR_NAMESPACE=${self.triggers.namespace} METRICS_EXPORTER_NAMESPACE=${self.triggers.namespace} bash
    EOF
  }
}
