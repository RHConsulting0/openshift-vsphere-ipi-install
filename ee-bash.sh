#!/bin/bash

# Ansible expects yaml for encrypted files
# https://docs.ansible.com/ansible/latest/user_guide/vault.html 
# https://docs.ansible.com/ansible/latest/collections/ansible/builtin/vault_module.html

CLUSTER=$1
ENV=$2


# Container execution environment
#EXECUTION_CONTAINER="registry.redhat.io/ansible-automation-platform-25/ee-supported-rhel9:latest"
EXECUTION_CONTAINER="ocp-provision-ee:latest"


# Project and Ansible directories
PROJECT_DIR="$(pwd)"
ANSIBLE_DIR="ansible"

# Run the Ansible playbook in a container
printf "Podman container starting...\n"
podman run --rm -it \
  --ipc=host \
  --user=root \
  --group-add=root \
  -v $PROJECT_DIR/$ANSIBLE_DIR:/runner/project:Z \
  -v $PROJECT_DIR/all-clusters-resources:/runner/all-clusters-resources:Z \
  $EXECUTION_CONTAINER


