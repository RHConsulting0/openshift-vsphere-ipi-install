#!/bin/bash
# . 010-run-prep-cluster-install.sh <cluster> <env>
# Example: . 010-run-prep-cluster-install.sh lab lab  
CLUSTER=$1
ENV=$2

# Project and Ansible directories
PROJECT_DIR="/home/miryan/Documents/projects/odfl/repos/openshift-vsphere-ipi-install"
ANSIBLE_DIR="ansible"

podman run --rm \
  -v ${PROJECT_DIR}/${ANSIBLE_DIR}:/runner/project:Z \
  -v ${PROJECT_DIR}/resources:/runner/resources:Z \
  -v ${PROJECT_DIR}/${ANSIBLE_DIR}/secrets/lab:/runner/project/secrets/lab:Z \
  -v ~/.ansible:/home/runner/.ansible:Z \
  registry.redhat.io/ansible-automation-platform-25/ee-supported-rhel9:latest \
  ansible-playbook -i /runner/project/inventory.yml \
    -e @/runner/project/group_vars/cluster/${CLUSTER}/all.yaml \
    -e @/runner/project/group_vars/env/${ENV}/default-vault.yaml \
    -e @/runner/project/group_vars/env/${ENV}/all.yaml \
    -e @/runner/resources/pull-secret.json \
    -e @/runner/project/secrets/${CLUSTER}/pull-secret.json \
    --vault-password-file=/runner/resources/vault-password.txt \
    /runner/project/prep_cluster_install.yaml -vvvv


