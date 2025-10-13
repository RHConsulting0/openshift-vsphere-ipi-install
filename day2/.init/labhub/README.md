# Init - foundation1

This kustomization uses a combination of the actual applications that will be deployed via Red Hat OpenShift GitOps (ArgoCD) Applications and Red Hat Advanced Cluster Management for Kubernetes (Open Cluster Management) Policies to the labhub cluster to initialize the gitops feedback loop between the two.

It assumes that OpenShift GitOps (ArgoCD) operator is installed and available.

For use with this playbook - [init-gitops.yaml](../../../ansible/init_gitops.yaml)
