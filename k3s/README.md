# K3s Deployment

It would be nice to fully automate the provisioning of the K3s machine, but for now I'll put the instructions for it here.

## Instructions

1. Create a VM and install Ubuntu Server
2. Setup the SSH user (with the below commands), and take note of the private key (at /home/k3s/.ssh/ed25519)
   1. Add k3s user and change into its shell:
        ```
        sudo useradd k3s &&
        sudo mkhomedir_helper k3s &&
        sudo usermod -s /bin/bash k3s &&
        sudo echo -e "k3s ALL=(ALL) NOPASSWD: ALL" | sudo tee -a /etc/sudoers &&
        sudo su - k3s
        ```
   2. Setup k3s SSH keys:
        ```
        mkdir -p /home/k3s/.ssh &&
        ssh-keygen -f /home/k3s/.ssh/ed25519 -N '' -t ed25519 &&
        cat /home/k3s/.ssh/ed25519.pub  | sudo tee -a /home/k3s/.ssh/authorized_keys
        ```
3. Create 'terraform.tfvars' in this directory, and populate with the required values
4. Run the Terraform in this directory
5. Get the kubeconfig values (at /etc/rancher/k3s/k3s.yaml)

## Truenas / democratic-csi minimum size hack script

```sh
for d in ./*/ ; do (cd "$d" && truncate -s 2G DO_NOT_REMOVE_MIN_SIZE_HACK); done
```
