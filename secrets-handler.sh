#!/bin/bash

# secrets-handler.sh
# Processes sensitive files using ansible-vault in a podman container

# Project and Ansible directories   
PROJECT_DIR="/home/miryan/Documents/projects/odfl/repos/openshift-vsphere-ipi-install"
ANSIBLE_DIR="ansible"

# Encrypt pull-secret.json using ansible-vault in a podman container
PLAIN_TEXT_PULL_SECRET="/runner/all-clusters-resources/pull-secret.json"
PULL_SECRET="/runnner/project/secrets/lab/pull-secret.json"

# SSH keys
RSA_KEY="/runner/project/secrets/lab/id_rsa_odfl"
ED25519_KEY="/runner/project/secrets/lab/id_ed25519_odfl"

# Vault password file
VAULT_PWD="/runner/all-clusters-resources/vault-password.txt"

# Cert trust bundle
TRUST_BUNDLE="/runner/all-clusters-resources/lab/ca-bundle.crt"

# VCenter password
VSPHERE_PASSWORD="/runner/all-clusters-resources/lab/vsphere-password.txt"


# Container execution environment
EXECUTION_CONTAINER="ocp-provision-ee:latest"

ACTION=$1
TARGET_FILE=$2
VAULT_PWD_FILE=$3
OUTPUT_FILE=$4 


# Actions
ENCRYPT="encrypt"
VIEW="view"
DECRYPT="decrypt"


# vault_podman $ACTION $TARGET_FILE $VAULT_PWD_FILE $OUTPUT_FILE


# Function to run ansible-vault commands in a podman container
vault_podman() {
    local action="$1"       # encrypt, decrypt, or view
    local file="$2"         # path to file
    local passfile="$3"     # vault password file path
    local output="$4"       # optional output file

    if [ -n "$output" ]; then
        podman run --rm \
          --ipc=host \
          --user=root \
          --group-add=root \
          -v ${PROJECT_DIR}/${ANSIBLE_DIR}:/runner/project:Z \
          -v ${PROJECT_DIR}/all-clusters-resources:/runner/all-clusters-resources:Z \
          $EXECUTION_CONTAINER \
            sh -c "ansible-vault ${action} ${file} \
                  --vault-password-file=${passfile} \
                  --output ${output}"
    else
        podman run --rm \
          --ipc=host \
          --user=root \
          --group-add=root \
          -v ${PROJECT_DIR}/${ANSIBLE_DIR}:/runner/project:Z \
          -v ${PROJECT_DIR}/all-clusters-resources:/runner/all-clusters-resources:Z \
          $EXECUTION_CONTAINER \
            sh -c "ansible-vault ${action} ${file} \
                  --vault-password-file=${passfile}"
    fi
}

