---
display_name: KubeVirt VM
description: Full Linux VMs on the homelab k3s cluster (docker-in-docker ready)
icon: /emojis/1f5a5.png
---

# KubeVirt VM

Full Ubuntu 24.04 virtual machines on the homelab cluster — a real kernel, so
privileged workloads run natively: dockerd/containerd, systemd, kernel
modules, eBPF experiments. No privileged pods.

- Root disk is cloned from the golden `ubuntu-noble-server-cloudimg-amd64`
  image (managed in `iac/kubevirt/images.tf`) and persists across restarts.
- Docker is preinstalled and the `coder` user is in the `docker` group.
- Stop = VM powered off (disk kept); restart takes ~1–2 min after the first
  clone. First start clones the root disk, so expect a few minutes.
- CPU/memory are **pinned** (requests = limits): a VM reserves what it asks
  for, unlike pod workspaces which only reserve a small floor.

Pre-bake tools into a golden image (see `iac/kubevirt/images.tf`) to skip
cloud-init package installs on first boot.
