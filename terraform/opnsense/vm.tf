resource "kubectl_manifest" "opnsense_kubevirt_vm" {
  yaml_body = yamlencode({
    apiVersion = "kubevirt.io/v1"
    kind       = "VirtualMachine"

    metadata = {
      name      = "opnsense"
      namespace = kubernetes_namespace.opnsense.metadata[0].name

      labels = {
        "kubevirt.io/vm" = "opnsense"
      }
    }

    spec = {
      runStrategy = "RerunOnFailure"

      template = {
        metadata = {
          labels = {
            "kubevirt.io/vm" = "opnsense"
          }
        }

        spec = {
          architecture = "amd64"

          domain = {
            devices = {
              disks = [
                {
                  disk = {
                    bus = "virtio"
                  }
                  name = "datavolumedisk1"
                },
              ]

              autoattachPodInterface = false

              hostDevices = [
                # the two ports are in different IOMMU groups, so they have to be passed in separately
                {
                  deviceName = "${var.server_base_domain}/opnsense_nic"
                  name       = "opnsense_nic_port_1"
                },
                {
                  deviceName = "${var.server_base_domain}/opnsense_nic"
                  name       = "opnsense_nic_port_2"
                },
              ]
            }

            machine = {
              type = "q35"
            }

            resources = {
              requests = {
                memory = "8Gi"
                cpu    = 4
              }
              limits = {
                memory = "8Gi"
                cpu    = 4
              }
            }
          }

          terminationGracePeriodSeconds = 60

          volumes = [
            {
              dataVolume = {
                name = "opnsense-disk"
              }
              name = "datavolumedisk1"
            },
          ]
        }

        networks = []
      }

      dataVolumeTemplates = [
        {
          metadata = {
            name = "opnsense-disk"
          }

          spec = {
            pvc = {
              accessModes = [
                "ReadWriteOnce"
              ]

              storageClassName = "openebs-zfs-localpv-general"

              resources = {
                requests = {
                  storage = "10Gi"
                }
              }
            }

            source = {
              pvc = {
                namespace = kubernetes_namespace.opnsense.metadata[0].name
                name      = null_resource.image_upload.triggers.image_upload_name
              }
            }
          }
        },
      ]
    }
  })

  wait_for {
    field {
      key   = "status.ready"
      value = "true"
    }
  }

  depends_on = [
    null_resource.image_upload,
  ]

  lifecycle {
    prevent_destroy = true
  }
}
