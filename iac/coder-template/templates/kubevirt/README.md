---
display_name: KubeVirt VM
description: Full Linux VMs on the homelab k3s cluster (docker-in-docker ready)
icon: /emojis/1f5a5.png
---

# KubeVirt VM

Full Ubuntu 26.04 (Resolute) LTS virtual machines on the homelab cluster —
a real kernel, so privileged workloads run natively: dockerd/containerd,
systemd, kernel modules, eBPF experiments. No privileged pods.

Persistence mirrors pod workspaces: **disposable root + persistent home**.

- Root boots fresh from the golden `coder-workspace-ubuntu-resolute` image
  (ephemeral overlay, discarded on stop): every start is a pristine first
  boot — tools installed ad-hoc during a session vanish; pre-bake them into
  the golden image (see `iac/coder/golden-image.tf`) or manage via
  [dotfiles](https://coder.com/docs/dotfiles).
- `/home/coder` is a persistent ZFS-backed PVC that survives restarts.
- Optional **Claude Code** and **OpenCode** modules (`claude_enabled` /
  `opencode_enabled` parameters) — CLI tools install on start, credentials
  persist on the home volume, OpenCode gets a dashboard web app via
  AgentAPI.
- Docker is installed on every start (~1–2 min of apt). Bake it into the
  golden image to skip that.
- CPU/memory are **pinned** (requests = limits): a VM reserves what it asks
  for, unlike pod workspaces which only reserve a small floor.
- Stop = VM powered off; start ≈ 1.5–2 min (boot + cloud-init + agent).
