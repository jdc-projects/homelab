# foundation

These Terraform deployments are to deploy foundational services required by everything else.
This includes the Traefik ingress and self-hosted Github runners for the organisation this project is hosted in.

Since the self-hosted runners are started by this deployment, this deployment uses Github hosted runners.
For this reason, the runtime of this component should be kept to a minimum.

This Terraform deployment is split into two.
This is because some elements deploy (and then others use) CRDs.
A limitation of Terraform means that the CRDs and CRs must be deployed separately, hence the two parts.
