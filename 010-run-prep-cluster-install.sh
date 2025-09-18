#!/usr/bin/env bash
#
# 010-run-prep-cluster-install.sh
# Protect against sourcing – must be run, not sourced.
#
# If the script is being sourced (BASH_SOURCE[0] != $0), exit with a warning.
if [ "${BASH_SOURCE[0]}" != "$0" ]; then
  echo "ERROR: This script must be executed, not sourced."
  echo "Run it like:  ./010-run-prep-cluster-install.sh lab lab"
  return 1 2>/dev/null || exit 1
fi

CLUSTER=$1
ENV=$2

# Container execution environment
# This script creates the secrets Ansible Vault      
#EXECUTION_CONTAINER="registry.redhat.io/ansible-automation-platform-25/ee-supported-rhel9:latest"
EXECUTION_CONTAINER="localhost/ocp-provision-ee:latest"

# Project and Ansible directories
PROJECT_DIR="/home/miryan/Documents/projects/odfl/repos/openshift-vsphere-ipi-install"
ANSIBLE_DIR="ansible"

# Run the Ansible playbook in a container
printf "Podman container starting...\n"
podman run --rm \
  -u $(id -u):$(id -g) \
  -v $PROJECT_DIR/$ANSIBLE_DIR/tmpdir:/runner/project/tmpdir:Z \
  -v $PROJECT_DIR/$ANSIBLE_DIR/ansible-logs:/runner/project/ansible-logs:Z \
  -v $PROJECT_DIR/$ANSIBLE_DIR:/runner/project:Z \
  -v $PROJECT_DIR/resources:/runner/resources:Z \
  -v $PROJECT_DIR/$ANSIBLE_DIR/secrets/lab:/runner/project/secrets/lab:Z \
  -v ~/.ansible:/home/runner/.ansible:Z \
  $EXECUTION_CONTAINER \
  ansible-playbook -i /runner/project/inventory.yml \
    -e @/runner/project/group_vars/cluster/${CLUSTER}/all.yaml \
    -e @/runner/project/group_vars/env/${ENV}/default-vault.yaml \
    -e @/runner/project/group_vars/env/${ENV}/all.yaml \
    -e @/runner/resources/pull-secret.json \
    -e @/runner/project/secrets/${CLUSTER}/pull-secret.json \
    --vault-password-file=/runner/resources/vault-password.txt \
    /runner/project/prep_cluster_install.yaml -vvv


