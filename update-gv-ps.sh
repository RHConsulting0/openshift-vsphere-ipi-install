#!/bin/bash

RESOURCE_DIR="/home/miryan/Documents/projects/odfl/repos/openshift-vsphere-ipi-install/all-clusters-resources"
ANSIBLE_DIR="/home/miryan/Documents/projects/odfl/repos/openshift-vsphere-ipi-install/ansible"


#ansible-vault edit $ANSIBLE_DIR/group_vars/pull-secret.yaml --vault-password-file=$RESOURCE_DIR/vault-password.txt
ansible-vault encrypt $RESOURCE_DIR/pull-secret.json --vault-password-file=$RESOURCE_DIR/vault-password.txt --output $ANSIBLE_DIR/group_vars/pull-secret.yaml
