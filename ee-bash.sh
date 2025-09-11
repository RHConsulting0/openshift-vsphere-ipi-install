#!/bin/bash

# Ansible expects yaml for encrypted files
# https://docs.ansible.com/ansible/latest/user_guide/vault.html 
# https://docs.ansible.com/ansible/latest/collections/ansible/builtin/vault_module.html

# Project and Ansible directories
PROJECT_DIR="/home/miryan/Documents/projects/odfl/repos/openshift-vsphere-ipi-install"
ANSIBLE_DIR="ansible"


podman run --rm -it \
  -v ${PROJECT_DIR}/${ANSIBLE_DIR}:/runner/project:Z \
  -v ${PROJECT_DIR}/${ANSIBLE_DIR}/group_vars/cluster:/runner/project/group_vars/cluster:Z \
  -v ${PROJECT_DIR}/resources:/runner/resources:Z \
  -v ${PROJECT_DIR}/${ANSIBLE_DIR}/secrets/lab:/runner/project/secrets/lab:Z \
  -v ~/.ansible:/home/runner/.ansible:Z \
  registry.redhat.io/ansible-automation-platform-25/ee-supported-rhel9:latest \
  /bin/bash
