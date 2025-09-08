#!/bin/bash

ANSIBLE_DIR="/home/miryan/Documents/projects/odfl/repos/openshift-vsphere-ipi-install/ansible"

# Usage: ./run.sh <cluster> <env>
# Example: ./run.sh lab lab
CLUSTER=$1
ENV=$2

cd $ANSIBLE_DIR

if [ -z "$CLUSTER" ] || [ -z "$ENV" ]; then
  echo "Usage: $0 <cluster> <env>"
  return 1
fi
if [ ! -f inventory ]; then
  echo "Error: inventory file not found!"
  return 1
fi
if [ ! -f group_vars/cluster/${CLUSTER}/all.yaml ]; then
  echo "Error: group_vars/cluster/${CLUSTER}/all.yaml file not found!"
  return 1
fi
if [ ! -f group_vars/env/${ENV}/all.yaml ]; then
  echo "Error: group_vars/env/${ENV}/all.yaml file not found!"
  return 1
fi
if [ ! -f group_vars/env/${ENV}/default-vault.yaml ]; then
  echo "Error: group_vars/env/${ENV}/default-vault.yaml file not found!"
  return 1
fi
if [ ! -f group_vars/pull-secret.yaml ]; then
  echo "Error: group_vars/pull-secret.yaml file not found!"
  return 1
fi
if [ ! -f group_vars/cluster/${CLUSTER}/ssh-key.yaml ]; then
  echo "Error: group_vars/cluster/${CLUSTER}/ssh-key.yaml file not found!"
  return 1
fi
if [ ! -f ../resources/vault-password.txt ]; then
  echo "Error: ../resources/vault-password.txt file not found!"
  return 1
fi
if [ ! -f initialize_cluster.yaml ]; then
  echo "Error: initialize_cluster.yaml file not found!"
  return 1
fi

# Run the Ansible playbook in a container
podman run --rm \
  -v $(pwd):/runner/project:Z \
  -v $(pwd)/../resources:/runner/resources:Z \
  -v ~/.ansible:/home/runner/.ansible:Z \
  registry.redhat.io/ansible-automation-platform-25/ee-supported-rhel9:latest \
  ansible-playbook -i /runner/project/inventory \
    -e @/runner/project/group_vars/cluster/${CLUSTER}/all.yaml \
    -e @/runner/project/group_vars/env/${ENV}/default-vault.yaml \
    -e @/runner/project/group_vars/env/${ENV}/all.yaml \
    -e @/runner/project/group_vars/pull-secret.yaml \
    -e @/runner/project/group_vars/cluster/${CLUSTER}/ssh-key.yaml \
    --vault-password-file=/runner/resources/vault-password.txt \
    -vvvv /runner/project/initialize_cluster.yaml
