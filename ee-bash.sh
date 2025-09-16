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
PROJECT_DIR="/home/miryan/Documents/projects/odfl/repos/openshift-vsphere-ipi-install"
ANSIBLE_DIR="ansible"

#  
#  ansible-playbook -i /runner/project/inventory.yml \
#    -e @/runner/project/group_vars/cluster/${CLUSTER}/all.yaml \
#    -e @/runner/project/group_vars/env/${ENV}/default-vault.yaml \
#    -e @/runner/project/group_vars/env/${ENV}/all.yaml \
#    -e @/runner/project/secrets/${CLUSTER}/secrets.yaml \
#    --vault-password-file=/runner/resources/vault-password.txt \
#    /runner/project/initialize_cluster.yaml -vvvv


# NEED THESE??
# -v ${PROJECT_DIR}/${ANSIBLE_DIR}/group_vars/cluster:/runner/project/group_vars/cluster:Z \
# -v ${PROJECT_DIR}/${ANSIBLE_DIR}/secrets/lab:/runner/project/secrets/lab:Z \

# Run the Ansible playbook in a container
printf "Podman container starting...\n"
podman run --rm -it \
  -v $PROJECT_DIR/$ANSIBLE_DIR:/runner/project:Z \
  -v $PROJECT_DIR/$ANSIBLE_DIR/group_vars/cluster:/runner/project/group_vars/cluster:Z \
  -v $PROJECT_DIR/resources:/runner/resources:Z \
  -v $PROJECT_DIR/$ANSIBLE_DIR/secrets/lab:/runner/project/secrets/lab:Z \
  -v ~/.ansible:/home/runner/.ansible:Z \
  $EXECUTION_CONTAINER


