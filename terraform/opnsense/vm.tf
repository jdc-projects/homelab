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
                # {
                #   disk = {
                #     bus = "virtio"
                #   }
                #   name      = "datavolumedisk1"
                # },
                {
                  disk = {
                    bus = "virtio"
                  }
                  name = "datavolumedisk2"
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

            firmware = {
              bootloader = {
                efi = {
                  secureBoot = false
                }
              }
            }

            machine = {
              type = "q35"
            }

            resources = {
              requests = {
                memory = "16Gi"
                cpu    = 8
              }
              limits = {
                memory = "16Gi"
                cpu    = 8
              }
            }
          }

          terminationGracePeriodSeconds = 60

          volumes = [
            # {
            #   persistentVolumeClaim = {
            #     claimName = null_resource.image_upload.triggers.image_upload_name
            #   }
            #   name = "datavolumedisk1"
            # },
            {
              persistentVolumeClaim = {
                claimName = kubernetes_persistent_volume_claim.opnsense.metadata[0].name
              }
              name = "datavolumedisk2"
            },
          ]
        }

        networks = []
      }
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
}
