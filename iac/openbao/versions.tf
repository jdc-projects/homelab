locals {
  # =========================================================================
  # Application images
  # =========================================================================

  # OpenBao server image. Also used for the unseal sidecar (needs the `bao`
  # CLI) and the bootstrap job's init probe.
  # https://quay.io/repository/openbao/openbao
  openbao_image_tag = "2.7.2"

  # =========================================================================
  # Infrastructure images
  # =========================================================================

  # kubectl image for the bootstrap job (matches the pin in k3s/k3s.tf).
  # https://hub.docker.com/r/alpine/kubectl/tags
  kubectl_image = "alpine/kubectl:1.33.4"

  # =========================================================================
  # Helm chart versions
  # =========================================================================

  # OpenBao chart.
  # https://github.com/openbao/openbao-helm
  openbao_chart_version = "0.30.6"
}
