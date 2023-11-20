# K3s Deployment

It would be nice to fully automate the provisioning of the K3s machine, but for now I'll put the instructions for it here.

## Instructions

1. Create a VM and install Ubuntu Server
2. Setup the SSH user (with the below commands, run one after another), and take note of the private key (at /home/k3s/.ssh/ed25519)
   1. ```sudo useradd k3s```
   2. ```sudo mkhomedir_helper k3s```
   3. ```sudo echo -e "k3s ALL=(ALL) NOPASSWD: ALL" | sudo tee -a /etc/sudoers```
   4. ```sudo su - k3s```
   5. ```mkdir -p /home/k3s/.ssh```
   6. ```ssh-keygen -f /home/k3s/.ssh/ed25519 -N '' -t ed25519```
   7. ```cat /home/k3s/.ssh/ed25519.pub  | sudo tee -a /home/k3s/.ssh/authorized_keys```
3. Create 'terraform.tfvars' in this directory, and populate with the required values
4. Run the Terraform in this directory
5. Get the kubeconfig values (at /etc/rancher/k3s/k3s.yaml)
