resource "kubernetes_manifest" "opensearch" {
  manifest = {
    apiVersion = "opensearch.org/v1"
    kind       = "OpenSearchCluster"

    metadata = {
      name      = "opensearch"
      namespace = kubernetes_namespace.posthog.metadata[0].name
    }

    spec = {
      general = {
        version     = local.opensearch_version
        httpPort    = 9200
        serviceName = "opensearch"

        additionalConfig = {
          "plugins.security.disabled" = "true"
          # Match the node name the operator expects in cluster.initial_master_nodes
          "node.name" = "opensearch-bootstrap-0"
        }
      }

      nodePools = [
        {
          component = "nodes"
          replicas  = 1
          diskSize  = "10Gi"

          persistence = {
            pvc = {
              storageClass = "openebs-zfs-localpv-bulk"
              accessModes  = ["ReadWriteOnce"]
            }
          }

          jvm = "-Xms512m -Xmx512m"

          roles = [
            "cluster_manager",
            "data",
            "ingest",
          ]

          env = [
            { name = "DISABLE_INSTALL_DEMO_CONFIG", value = "true" },
          ]

          resources = {
            requests = {
              cpu    = "250m"
              memory = "1Gi"
            }
            limits = {
              cpu    = "500m"
              memory = "1Gi"
            }
          }
        }
      ]
    }
  }

  field_manager {
    force_conflicts = true
  }

  computed_fields = [
    "metadata.labels",
    "metadata.annotations",
  ]

  lifecycle {
    prevent_destroy = true
  }
}
