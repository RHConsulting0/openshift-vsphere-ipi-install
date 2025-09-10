#!/bin/bash

# Project and Ansible directories   
PROJECT_DIR="/home/miryan/Documents/projects/odfl/repos/openshift-vsphere-ipi-install"
ANSIBLE_DIR="ansible"

# Encrypt pull-secret.json using ansible-vault in a podman container
PLAIN_TEXT_PULL_SECRET="/runner/resources/pull-secret.json"
PULL_SECRET="/runnner/project/secrets/lab/pull-secret.json"

# SSH keys
RSA_KEY="/runner/project/secrets/lab/id_rsa_odfl"
ED25519_KEY="/runner/project/secrets/lab/id_ed25519_odfl"

# Vault password file
VAULT_PWD="/runner/resources/vault-password.txt"

# Actions
ENCRYPT="encrypt"
VIEW="view"
DECRYPT="decrypt"

printf "\nEncrypting files using ansible-vault in a podman container...\n\n"
vault_podman $ENCRYPT $PLAIN_TEXT_PULL_SECRET $VAULT_PWD $PULL_SECRET
printf "\nEncrypted file created[%s]: %s\n\n" $PULL_SECRET $(cat $PULL_SECRET)
vault_podman $ENCRYPT $RSA_KEY $VAULT_PWD 
printf "\nEncrypted file created[%s]: %s\n\n" $RSA_KEY $(cat $RSA_KEY)
vault_podman $ENCRYPT $ED25519_KEY $VAULT_PWD
printf "\nEncrypted file created[%s]: %s\n\n" $ED25519_KEY $(cat $ED25519_KEY)


# sanity check for pull-secret.json
printf "Resources file [$(PROJECT_DIR)/resources/pull-secret.json] - should not be encrypted\n\n"
cat $(PROJECT_DIR)/resources/pull-secret.json

podman run --rm -v ${PROJECT_DIR}/${ANSIBLE_DIR}:/runner/project:Z \
  registry.redhat.io/ansible-automation-platform-25/ee-supported-rhel9:latest \
  sh -c "printf \"\nsanity check for folder: ${PROJECT_DIR}/${ANSIBLE_DIR}/secrets\n\" && ls -l ${PROJECT_DIR}/${ANSIBLE_DIR}/secrets"

printf "\nCOMPLETE\n"


# Function to run ansible-vault commands in a podman container
vault_podman() {
    local action="$1"       # encrypt, decrypt, or view
    local file="$2"         # path to file
    local passfile="$3"     # vault password file path
    local output="$4"       # optional output file

    if [ -n "$output" ]; then
        podman run --rm \
          -v ${PROJECT_DIR}/${ANSIBLE_DIR}:/runner/project:Z \
          -v ${PROJECT_DIR}/resources:/runner/resources:Z \
          -v ~/.ansible:/home/runner/.ansible:Z \
          registry.redhat.io/ansible-automation-platform-25/ee-supported-rhel9:latest \
            sh -c "ansible-vault ${action} ${file} \
                  --vault-password-file=${passfile} \
                  --output /runner/project/${output}"
    else
        podman run --rm \
          -v ${PROJECT_DIR}/${ANSIBLE_DIR}:/runner/project:Z \
          -v ${PROJECT_DIR}/resources:/runner/resources:Z \
          -v ~/.ansible:/home/runner/.ansible:Z \
          registry.redhat.io/ansible-automation-platform-25/ee-supported-rhel9:latest \
            sh -c "ansible-vault ${action} /runner/project/${file} \
                  --vault-password-file=${passfile}"
    fi
}

