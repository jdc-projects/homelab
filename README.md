# homelab

Infrastructure and code for deploying my Homelab. There are some dependencies.

## Prequisites

This system requires that some setup is completed on the first:

* The Kubernetes management interface port must be exposed to the internet (through router port forwarding), alongside HTTP and HTTPS
* The root must point towards the public IP
* Setup of the [Github Org app](https://github.com/actions/actions-runner-controller/blob/master/docs/using-arc-across-organizations.md)
* Truenas setup as required for democratic-csi

## Environment variables required for build

### Secrets

* CLOUDFLARE_ACME_TOKEN
* CLOUDFLARE_DDNS_TOKEN
* GH_ORG_RUNNERS_APP_PRIVATE_KEY
* IDRAC_PASSWORD
* IDRAC_USERNAME
* KUBE_CLIENT_CERT_DATA
* KUBE_CLIENT_KEY_DATA
* KUBE_CLUSTER_CA_CERT_DATA
* SMTP_PASSWORD
* VELERO_S3_SECRET_ACCESS_KEY
* K3S_SSH_PRIVATE_KEY
* K3S_IP_ADDRESS
* TRUENAS_API_KEY
* TRUENAS_IP_ADDRESS

### Variables

* GH_ORG_NAME
* GH_ORG_RUNNERS_APP_ID
* GH_ORG_RUNNERS_APP_INSTALLATION_ID
* SERVER_BASE_DOMAIN
* SERVER_KUBE_PORT
* SMTP_PORT
* SMTP_SERVER
* SMTP_USERNAME
* VELERO_S3_ACCESS_KEY_ID
* VELERO_S3_BUCKET_NAME
* VELERO_S3_REGION
* VELERO_S3_URL
* TRUENAS_K3S_DATASET
* TRUENAS_K3S_SNAPSHOT_DATASET

## Disaster Recovery

1. Provision server(s):
   1. K3s server(s)
   2. Truenas
2. Run DR pipeline
3. Wait for Velero restore to finish
   1. If any PVCs are stuck pending, it's likely because they contained no data - if that is the case, delete them and continue
4. Remove Harbor Docker hub proxy config object from Terraform state (in harbor-config):
    ```
    terraform state rm ssh_sensitive_resource.k3s_registries_config_copy
    ```
5. Run deploy pipeline with non-self-hosted runners

## Stuff to do / ideas

* [Trivy](https://github.com/aquasecurity/Trivy) for vulnerability scanning
* Migrate to [ARC scale sets](https://github.com/actions/actions-runner-controller/discussions/2775)
* Add metrics into Grafana with Mimir
* Create (and use) Terraform module for ingress
* Add a proper, secure secrets manager
* Setup Dependabot
* [KubeVirt](https://kubevirt.io/user-guide/operations/installation/)?
* [Appflowy](https://www.appflowy.io/)
* Create and deploy solution to update Truenas dataset stuff after Velero restore (see [here](https://github.com/democratic-csi/democratic-csi/issues/352))
* [Firezone](https://oopflow.medium.com/how-to-deploy-firezone-on-kubernetes-3373c4ac1a86) Wireguard VPN
