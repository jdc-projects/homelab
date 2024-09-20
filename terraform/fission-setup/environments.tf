resource "kubernetes_manifest" "fission_environment" {
  # https://fission.io/environments/
  for_each = tomap({
    nodejs = tomap({
      version       = 1
      runtime_image = "ghcr.io/fission/node-env:1.32.4"
      builder_image = null
      poolsize      = 3
    })
    python = tomap({
      version       = 1
      runtime_image = "ghcr.io/fission/python-env:1.34.2"
      builder_image = null
      poolsize      = 3
    })
  })

  manifest = {
    apiVersion = "fission.io/v1"
    kind       = "Environment"

    metadata = {
      name      = each.key
      namespace = data.terraform_remote_state.fission.outputs.fission_environments_namespace
    }

    spec = {
      version = each.value.version
      runtime = {
        image = each.value.runtime_image
      }
      builder = null != each.value.builder_image ? {
        image = each.value.builder_image
      } : null

      allowedFunctionsPerContainer = "infinite"

      resources = {
        requests = {
          cpu    = "100m"
          memory = "200Mi"
        }

        limits = {
          cpu    = "200m"
          memory = "500Mi"
        }
      }

      poolsize = each.value.poolsize
    }
  }
}
