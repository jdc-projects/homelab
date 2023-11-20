# K3s Deployment

It would be nice to fully automate the provisioning of the K3s machine, but for now I'll put the instructions for it here.

## Instructions

1. Create a VM and install Ubuntu Server
2. Setup the SSH user (with the below commands), and take note of the private key (at /home/k3s/.ssh/ed25519)
```
sudo useradd k3s
sudo echo -e "k3s ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
sudo mkdir -p /home/k3s/.ssh
sudo ssh-keygen -f /home/k3s/.ssh/ed25519 -N '' -t ed25519
sudo cat /home/k3s/.ssh/ed25519.pub >> /home/k3s/.ssh/authorized_keys
```
3. Create 'terraform.tfvars' in this directory, and populate with the required values
4. Run the Terraform in this directory
5. Get the kubeconfig values (at /etc/rancher/k3s/k3s.yaml)
