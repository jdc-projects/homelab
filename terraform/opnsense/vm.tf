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
                #   name = "install-image"
                # },
                # {
                #   cdrom = {
                #     bus = "sata"
                #   }
                #   name = "config-xml"
                # },
                {
                  disk = {
                    bus = "virtio"
                  }
                  name = "os-disk"
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
            #   dataVolume = {
            #     name = null_resource.image_upload.triggers.image_upload_name
            #   }
            #   name = "install-image"
            # },
            # {
            #   dataVolume = {
            #     name = null_resource.config_xml.triggers.image_upload_name
            #   }
            #   name = "config-xml"
            # },
            {
              persistentVolumeClaim = {
                claimName = kubernetes_persistent_volume_claim.opnsense.metadata[0].name
              }
              name = "os-disk"
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
