resource "kubernetes_persistent_volume_claim" "keycloak_db" {
  metadata {
    name      = "keycloak-db"
    namespace = kubernetes_namespace.keycloak.metadata[0].name
  }

  spec {
    access_modes = ["ReadWriteMany"]

    resources {
      requests = {
        storage = "1Gi"
      }
    }
  }

  lifecycle {
    prevent_destroy = false

    replace_triggered_by = [null_resource.keycloak_version]

    create_before_destroy = false
  }
}
