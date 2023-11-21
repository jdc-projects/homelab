resource "kubernetes_config_map" "storage_users" {
  metadata {
    name      = "storage-users"
    namespace = kubernetes_namespace.ocis.metadata[0].name
  }

  data = {
    storage-uuid = random_uuid.storage_users_storage_uuid.result
  }
}

resource "kubernetes_config_map" "graph" {
  metadata {
    name      = "graph"
    namespace = kubernetes_namespace.ocis.metadata[0].name
  }

  data = {
    application-id = random_uuid.graph_application_id.result
  }
}
