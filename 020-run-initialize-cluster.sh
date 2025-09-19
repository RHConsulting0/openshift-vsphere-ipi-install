#!/usr/bin/env bash
#
# 020-run-initialize-cluster.sh <cluster> <env>
# Protect against sourcing – must be run, not sourced.
#
# If the script is being sourced (BASH_SOURCE[0] != $0), exit with a warning.
if [ "${BASH_SOURCE[0]}" != "$0" ]; then
  echo "ERROR: This script must be executed, not sourced."
  echo "Run it like: ./020-run-initialize-cluster.sh lab lab"
  return 1 2>/dev/null || exit 1
fi

CLUSTER=$1
ENV=$2

# Container execution environment      
EXECUTION_CONTAINER="ocp-provision-ee:latest"
#EXECUTION_CONTAINER="registry.redhat.io/ansible-automation-platform-25/ee-supported-rhel9:latest"

# Project and Ansible directories
PROJECT_DIR="$(pwd)"
ANSIBLE_DIR="ansible"


# Run the Ansible playbook in a container
printf "Podman container starting...\n"
podman run --rm \
  --ipc=host \
  --user=root \
  --group-add=root \
  -v $PROJECT_DIR/$ANSIBLE_DIR:/runner/project:Z \
  -v $PROJECT_DIR/resources:/runner/resources:Z \
  $EXECUTION_CONTAINER \
  ansible-playbook -i /runner/project/inventory.yml \
    -e @/runner/project/group_vars/cluster/${CLUSTER}/all.yaml \
    -e @/runner/project/group_vars/env/${ENV}/default-vault.yaml \
    -e @/runner/project/group_vars/env/${ENV}/all.yaml \
    -e @/runner/project/secrets/${CLUSTER}/secrets.yaml \
    --vault-password-file=/runner/resources/vault-password.txt \
    /runner/project/initialize_cluster.yaml -vvv


