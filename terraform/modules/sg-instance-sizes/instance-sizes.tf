resource "kubernetes_manifest" "sg_instance_profile" {
  for_each = {
    xs = {
      cpu    = "200m"
      memory = "500Mi"
    }
    s = {
      cpu    = "500m"
      memory = "1Gi"
    }
    m = {
      cpu    = "1"
      memory = "2Gi"
    }
    l = {
      cpu    = "2"
      memory = "4Gi"
    }
    xl = {
      cpu    = "4"
      memory = "8Gi"
    }
  }

  manifest = {
    apiVersion = "stackgres.io/v1"
    kind       = "SGInstanceProfile"

    metadata = {
      name      = each.key
      namespace = var.namespace
    }

    spec = {
      cpu    = each.value.cpu
      memory = each.value.memory
    }
  }
}
