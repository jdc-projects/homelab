# K3s Deployment

It would be nice to fully automate the provisioning of the K3s machine, but for now I'll put the instructions for it here.

## Instructions

1. Create a VM and install Ubuntu Server
2. Setup the SSH user (with the below commands), and take note of the private key (at /home/k3s/.ssh/ed25519)
   1. Add k3s user and change into its shell:
        ```sh
        sudo useradd k3s &&
        sudo mkhomedir_helper k3s &&
        sudo usermod -s /bin/bash k3s &&
        sudo echo -e "k3s ALL=(ALL) NOPASSWD: ALL" | sudo tee -a /etc/sudoers &&
        sudo su - k3s
        ```
   2. Setup k3s SSH keys:
        ```sh
        mkdir -p /home/k3s/.ssh &&
        ssh-keygen -f /home/k3s/.ssh/ed25519 -N '' -t ed25519 &&
        cat /home/k3s/.ssh/ed25519.pub  | sudo tee -a /home/k3s/.ssh/authorized_keys
        ```
3. Create 'terraform.tfvars' in this directory, and populate with the required values
4. Run OpenTofu in this directory
5. Get the kubeconfig values (at /etc/rancher/k3s/k3s.yaml)
7. Restart the server before deploying anything

## CNI: Calico (flannel disabled)

k3s's bundled flannel is disabled (`flannel-backend: none`, `disable-network-policy:
true` in `config.yaml`); the CNI is **Calico**, installed by `iac/calico/`
(tigera-operator + an `Installation` CR with an IPPool over `10.42.0.0/16`, VXLAN).

Why: this cluster is single-node and flannel derives its per-node subnet from the
immutable `node.spec.podCIDR` (a `/24` = 254 IPs), which it outgrew at ~300 pods.
Calico runs its own block-based IPAM that ignores `podCIDR`, so the node draws
`/26` blocks on demand from the `10.42.0.0/16` pool — effectively unbounded within
the cluster CIDR. `calico-node` (and the tigera-operator) run `hostNetwork: true`,
so Calico self-bootstraps on a CNI-less node: k3s's control plane runs without a
CNI, the operator comes up hostNetwork, deploys `calico-node` (hostNetwork), which
installs the CNI plugin, and only then do normal pods get wired.

### Bootstrap / restore ordering

Calico is base-layer infrastructure: it must exist before any workload can
schedule. The deploy pipeline runs `deploy-calico` early, ahead of everything that
schedules pods. Two recovery paths both work:

- **etcd-snapshot restore** (k3s native): Calico's resources live in etcd, so they
  are restored with everything else; on k3s start the hostNetwork `calico-node`
  DaemonSet reinstalls the CNI. Requires `flannel-backend: none` to still be in
  `config.yaml` (it is — `k3s.tf` owns it).
- **Fresh install + Velero restore** (disaster recovery to new hardware): provision
  the node (k3s.tf) → apply `iac/calico` → run `iac/velero-restore`. Calico is
  excluded from Velero backups (it is re-provisioned, not restored).

### Switching a running node from flannel to Calico (one-off migration)

Full re-IP of every pod once; brief cluster-wide networking outage while Calico
comes up. Take an etcd snapshot first.

```sh
# 1. safety net
sudo k3s etcd-snapshot save --name pre-calico

# 2. config.yaml now has flannel-backend=none + disable-network-policy=true (from k3s.tf)
sudo systemctl restart k3s          # flannel stops; pods lose networking until Calico is up

# 3. install Calico (operator + Installation CR) — run from the iac/calico dir:
#    tofu apply -auto-approve
#    calico-node (hostNetwork) comes up, installs the CNI, pods re-IP.

# 4. verify
kubectl -n calico-system get pods
kubectl get pods -A -o wide   # pods now have 10.42.x IPs from Calico's pool
```

Rollback: revert `config.yaml` (drop `flannel-backend: none`) + restart k3s, or
restore the `pre-calico` snapshot (`k3s server --cluster-reset
--cluster-reset-restore-path=.../pre-calico-*`).


