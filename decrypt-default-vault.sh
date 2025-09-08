#!/bin/bash

RESOURCE_DIR="/home/miryan/Documents/projects/odfl/repos/openshift-vsphere-ipi-install/resources"
DEFAULT_VAULT_FILE="/home/miryan/Documents/projects/odfl/repos/openshift-vsphere-ipi-install/ansible/group_vars/env/lab/default-vault.yaml"


ansible-vault decrypt /home/miryan/Documents/projects/odfl/repos/openshift-vsphere-ipi-install/ansible/group_vars/env/lab/default-vault.yaml --vault-password-file=$RESOURCE_DIR/vault-password.txt --output=$RESOURCE_DIR/default-vault.yaml.decrypted

