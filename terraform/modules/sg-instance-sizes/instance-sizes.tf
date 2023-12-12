resource "kubernetes_manifest" "sg_instance_profile" {
  for_each = {
    xs = {
      requests = {
        cpu    = "100m"
        memory = "256Mi"
      }
      limits = {
        cpu    = "200m"
        memory = "512Mi"
      }
    }
    s = {
      requests = {
        cpu    = "250m"
        memory = "500Mi"
      }
      limits = {
        cpu    = "500m"
        memory = "1Gi"
      }
    }
    m = {
      requests = {
        cpu    = "500m"
        memory = "1Gi"
      }
      limits = {
        cpu    = "1"
        memory = "2Gi"
      }
    }
    l = {
      requests = {
        cpu    = "1"
        memory = "2Gi"
      }
      limits = {
        cpu    = "2"
        memory = "4Gi"
      }
    }
    xl = {
      requests = {
        cpu    = "2"
        memory = "4Gi"
      }
      limits = {
        cpu    = "4"
        memory = "8Gi"
      }
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
      cpu    = each.value.limits.cpu
      memory = each.value.limits.memory

      requests = {
        cpu    = each.value.requests.cpu
        memory = each.value.requests.memory
      }
    }
  }

  computed_fields = [
    "spec.containers",
    "spec.requests.initContainers",
  ]
}
