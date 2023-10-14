# homelab

Infrastructure and code for deploying my Homelab. There are some dependencies.

## Prequisites

This system requires that some setup is completed on the first:
* The rule that restricts access to the Kubernetes managements interface must be removed:

```sh
sudo iptables -D INPUT -p tcp -m tcp --dport 6443 -m comment --comment "iX Custom Rule to drop connection requests to k8s cluster from external sources" -j DROP
```

* The Kubernetes management interface port must be exposed to the internet (through router port forwarding)
* The domain jack-chapman.co.uk must point towards my public IP

## Environment variables required for build

* KUBE_CLIENT_CERT_DATA
* KUBE_CLIENT_KEY_DATA
* KUBE_CLUSTER_CA_CERT_DATA
* (TF_VARS_server_base_domain)
* SERVER_KUBE_PORT

## Terraform environment variables

* TF_VARS_server_base_domain
* TF_VARS_jdc_projects_runners_app_id
* TF_VARS_jdc_projects_runners_app_installation_id
* TF_VARS_jdc_projects_runners_app_private_key
* TF_VARS_cloudflare_acme_token

## Stuff to do

* Migrate to [ARC scale sets](https://github.com/actions/actions-runner-controller/discussions/2775)
* Add metrics into Grafana with Mimir
* Create (and use) Terraform module for ingress
* Add a proper, secure secrets manager
* Setup Dependabot
