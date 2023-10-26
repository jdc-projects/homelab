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
* Setup of the [Github Org app](https://github.com/actions/actions-runner-controller/blob/master/docs/using-arc-across-organizations.md)

## Environment variables required for build

### Secrets

* DOCKER_HUB_USERNAME
* DOCKER_HUB_TOKEN
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

## Stuff to do

* [Docker registry proxy](https://docs.docker.com/docker-hub/mirror/#run-a-registry-as-a-pull-through-cache)
* Velero [CSI volume snapshots](https://velero.io/docs/v1.12/csi-snapshot-data-movement/#configure-a-backup-storage-location)
* [Trivy](https://github.com/aquasecurity/Trivy) for vulnerability scanning
* Migrate to [ARC scale sets](https://github.com/actions/actions-runner-controller/discussions/2775)
* Add metrics into Grafana with Mimir
* Create (and use) Terraform module for ingress
* Add a proper, secure secrets manager
* Setup Dependabot
* [KubeVirt](https://kubevirt.io/user-guide/operations/installation/)?
