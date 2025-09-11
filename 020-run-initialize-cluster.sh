#!/bin/bash

#. 020-run-initialize-cluster.sh <cluster> <env>
# Example: . 020-run-initialize-cluster.sh lab lab  
CLUSTER=$1
ENV=$2


# Project and Ansible directories
PROJECT_DIR="/home/miryan/Documents/projects/odfl/repos/openshift-vsphere-ipi-install"
ANSIBLE_DIR="ansible"


# cd $PROJECT_DIR
# printf "Current directory is: [%s]\n" $PROJECT_DIR
# printf "Current directory listing is: [%s]\n" "$(ls -lta $PROJECT_DIR)"

# printf "Current directory is: [%s]\n" $PROJECT_DIR/$ANSIBLE_DIR
# printf "Current directory listing is: [%s]\n" "$(ls -lta $PROJECT_DIR/$ANSIBLE_DIR)"

# if [ -z "$CLUSTER" ] || [ -z "$ENV" ]; then
#   echo "Usage: $0 <cluster> <env>"
#   return 1
# fi
# printf " Checking for file - $PROJECT_DIR/$ANSIBLE/inventory\n"
# if [ ! -f "$PROJECT_DIR/$ANSIBLE/inventory" ]; then
#   echo "Error: inventory file not found!"
#   return 1
# fi
# if [ ! -f "$PROJECT_DIR/$ANSIBLE/group_vars/cluster/${CLUSTER}/all.yaml" ]; then
#   echo "Error: group_vars/cluster/${CLUSTER}/all.yaml file not found!"
#   return 1
# fi
# if [ ! -f "$PROJECT_DIR/$ANSIBLE/group_vars/env/${ENV}/all.yaml" ]; then
#   echo "Error: group_vars/env/${ENV}/all.yaml file not found!"
#   return 1
# fi
# if [ ! -f "$PROJECT_DIR/$ANSIBLE/group_vars/env/${ENV}/default-vault.yaml" ]; then
#   echo "Error: group_vars/env/${ENV}/default-vault.yaml file not found!"
#   return 1
# fi
# if [ ! -f "$PROJECT_DIR/$ANSIBLE/secrets/pull-secret.json" ]; then
#   echo "Error: secrets/pull_secret.json file not found!"
#   return 1
# fi
# if [ ! -f "$PROJECT_DIR/$ANSIBLE/group_vars/cluster/${CLUSTER}/id_ed25519_odfl.pub" ]; then
#   echo "Error: group_vars/cluster/${CLUSTER}/id_ed25519_odfl.pub file not found!"
#   return 1
# fi
# if [ ! -f "$PROJECT_DIR/resources/vault-password.txt" ]; then
#   echo "Error: $PROJECT_DIR/resources/vault-password.txt file not found!"
#   return 1
# fi
# if [ ! -f $PROJECT_DIR/$ANSIBLE/initialize_cluster.yaml" ]; then
#   echo "Error: initialize_cluster.yaml file not found!"
#   return 1
# fi

# Run the Ansible playbook in a container
printf "Podman container starting...\n"
podman run --rm -it \
  -v ${PROJECT_DIR}/${ANSIBLE_DIR}:/runner/project:Z \
  -v ${PROJECT_DIR}/resources:/runner/resources:Z \
  -v ~/.ansible:/home/runner/.ansible:Z \
  registry.redhat.io/ansible-automation-platform-25/ee-supported-rhel9:latest \
  ansible-playbook -i /runner/project/inventory.yml \
    -e @/runner/project/group_vars/cluster/${CLUSTER}/all.yaml \
    -e @/runner/project/group_vars/env/${ENV}/default-vault.yaml \
    -e @/runner/project/group_vars/env/${ENV}/all.yaml \
    -e @/runner/project/secrets/${CLUSTER}/secrets.yaml \
    --vault-password-file=/runner/resources/vault-password.txt \
    /runner/project/initialize_cluster.yaml -vvvv

