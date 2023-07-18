# resource "null_resource" "ocis_helm_repo_clone" {
#   triggers = {
#     always_run = timestamp()
#   }

#   provisioner "local-exec" {
#     command = "git clone --depth 1 -b v0.4.0 https://github.com/owncloud/ocis-charts.git"
#   }
# }
