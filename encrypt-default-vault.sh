#!/bin/bash

RESOURCE_DIR="/home/miryan/Documents/projects/odfl/repos/openshift-vsphere-ipi-install/resources"
DEFAULT_VAULT_FILE="/home/miryan/Documents/projects/odfl/repos/openshift-vsphere-ipi-install/ansible/group_vars/env/lab/default-vault.yaml"


ansible-vault encrypt /home/miryan/Documents/projects/odfl/repos/openshift-vsphere-ipi-install/ansible/group_vars/env/lab/default-vault.yaml.decrypted --vault-password-file=$RESOURCE_DIR/vault-password.txt --output=$RESOURCE_DIR/default-vault.yaml

