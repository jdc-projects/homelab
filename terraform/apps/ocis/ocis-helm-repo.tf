resource "null_resource" "ocis_helm_repo" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = "git clone --depth 1 -b v0.3.0 https://github.com/owncloud/ocis-charts.git"
  }
}
