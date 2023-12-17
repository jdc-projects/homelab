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

## Stuff to do / ideas

* [Trivy](https://github.com/aquasecurity/Trivy) for vulnerability scanning
* Migrate to [ARC scale sets](https://github.com/actions/actions-runner-controller/discussions/2775)
* Add a proper, secure secrets manager
* Setup Dependabot
* [Appflowy](https://www.appflowy.io/)
* Create and deploy solution to update Truenas dataset stuff after Velero restore (see [here](https://github.com/democratic-csi/democratic-csi/issues/352))
* [Firezone](https://oopflow.medium.com/how-to-deploy-firezone-on-kubernetes-3373c4ac1a86) Wireguard VPN
* [Kubernetes Dashbaord](https://github.com/kubernetes/dashboard/tree/master/charts/helm-chart/kubernetes-dashboard) in a [read-only](https://discuss.kubernetes.io/t/readonly-kubernetes-dashboard/5451/2) mode
* [Minio operator](https://github.com/minio/operator) (and use in appplications in place of the existing Helm deployments)
* [Prometheus operator](https://github.com/prometheus-operator/prometheus-operator)
