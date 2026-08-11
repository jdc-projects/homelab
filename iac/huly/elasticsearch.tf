# ECK-managed Elasticsearch for Huly's fulltext service.
#
# See iac/elasticsearch-operator/README.md for gotchas:
# - Don't set discovery.type: single-node (ECK handles single-node bootstrap)
# - Don't set xpack.security.enabled (ECK reserves it; auth is mandatory)
# - Plugins installed via init container
#
# Auth: ECK mandates the `elastic` superuser and generates a random password
# in the Secret `<cr>-es-elastic-user`. We read it back via a data source
# (below) after a null_resource polls for the Secret's existence. This avoids
# the `wait` block (which triggers a kubernetes provider bug — "inconsistent
# result after apply" — due to ECK populating default empty spec objects the
# provider doesn't expect). ECK overwrites any pre-created Secret data, so
# pre-creating the Secret with our own password doesn't work.

resource "kubernetes_manifest" "elasticsearch" {
  manifest = {
    apiVersion = "elasticsearch.k8s.elastic.co/v1"
    kind       = "Elasticsearch"

    metadata = {
      name      = "elastic"
      namespace = kubernetes_namespace.huly.metadata[0].name
    }

    spec = {
      version = "7.17.29"

      # Plaintext HTTP - matches what Huly's @elastic/elasticsearch JS client
      # expects (its createElasticAdapter(url) takes a plain URL with no TLS
      # config). Auth is still on (ECK mandates it); the elastic password
      # is passed via URL-embedded credentials in huly.tf's local.es_url.
      http = {
        tls = {
          selfSignedCertificate = {
            disabled = true
          }
        }
      }

      nodeSets = [
        {
          name  = "default"
          count = 1

          config = {
            "node.store.allow_mmap" = "false"
          }

          podTemplate = {
            spec = {
              initContainers = [
                {
                  name    = "install-plugins"
                  command = ["/bin/sh", "-c"]
                  args = [
                    "bin/elasticsearch-plugin install --batch ingest-attachment"
                  ]
                }
              ]

              containers = [
                {
                  name = "elasticsearch"

                  env = [
                    { name = "ES_JAVA_OPTS", value = "-Xms512m -Xmx512m" }
                  ]

                  resources = {
                    requests = {
                      cpu    = "250m"
                      memory = "2Gi"
                    }
                    limits = {
                      cpu    = "1"
                      memory = "2Gi"
                    }
                  }
                }
              ]
            }
          }

          volumeClaimTemplates = [
            {
              metadata = { name = "elasticsearch-data" }
              spec = {
                accessModes      = ["ReadWriteOnce"]
                storageClassName = "openebs-zfs-localpv-bulk"
                resources = {
                  requests = {
                    storage = "10Gi"
                  }
                }
              }
            }
          ]
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

  # No `wait` block — it triggers a kubernetes provider bug ("inconsistent
  # result after apply"). The null_resource below handles readiness instead.

  lifecycle {
    prevent_destroy = true
  }
}

# Polls for the elastic-user Secret to exist before the data source reads it.
# ECK creates this Secret asynchronously after the ES cluster boots (which
# takes 1-3 min). Without this, the data source would fail on first apply
# because the Secret doesn't exist yet. Uses local-exec kubectl (same pattern
# as iac/clickhouse-operator/clickhouse-operator.tf).
resource "null_resource" "wait_for_es_secret" {
  triggers = {
    namespace = kubernetes_namespace.huly.metadata[0].name
  }

  provisioner "local-exec" {
    command = <<-EOF
      for i in $(seq 1 60); do
        kubectl --kubeconfig ${path.module}/../cluster.yml get secret -n ${kubernetes_namespace.huly.metadata[0].name} elastic-es-elastic-user 2>/dev/null && exit 0
        echo "waiting for elastic-es-elastic-user Secret... ($i)"
        sleep 5
      done
      echo "elastic-es-elastic-user Secret never appeared" >&2
      exit 1
    EOF
  }
}

# Read the ECK-generated elastic password. depends_on the null_resource so
# the Secret exists by the time this is read (deferred to apply phase).
data "kubernetes_secret" "es_elastic_user" {
  metadata {
    name      = "elastic-es-elastic-user"
    namespace = kubernetes_namespace.huly.metadata[0].name
  }

  depends_on = [null_resource.wait_for_es_secret]
}
