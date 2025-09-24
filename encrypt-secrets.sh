#!/bin/bash

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

# Actions
ENCRYPT="encrypt"
VIEW="view"
DECRYPT="decrypt"

# Encrypt files using ansible-vault in a podman container
printf "\nEncrypting files using ansible-vault in a podman container...\n\n"
printf "Calling... vault_podman %s %s %s %s" $ENCRYPT $PLAIN_TEXT_PULL_SECRET $VAULT_PWD $PULL_SECRET
vault_podman $ENCRYPT $PLAIN_TEXT_PULL_SECRET $VAULT_PWD $PULL_SECRET
printf "\nEncrypted file created[%s]: %s\n\n" $PULL_SECRET $(cat $PULL_SECRET)

# rsa key
printf "Calling... vault_podman %s %s %s" $ENCRYPT $RSA_KEY $VAULT_PWD 
vault_podman $ENCRYPT $RSA_KEY $VAULT_PWD 
printf "\nEncrypted file created[%s]: %s\n\n" $RSA_KEY $(cat $RSA_KEY)

# ssh-ed25519 key 
printf "Calling... vault_podman %s %s %s" $ENCRYPT $ED25519_KEY $VAULT_PWD
vault_podman $ENCRYPT $ED25519_KEY $VAULT_PWD
printf "\nEncrypted file created[%s]: %s\n\n" $ED25519_KEY $(cat $ED25519_KEY)


# sanity check for pull-secret.json
printf "Resources file [$PROJECT_DIR/all-clusters-resources/pull-secret.json] - should not be encrypted\n\n"
cat $PROJECT_DIR/all-clusters-resources/pull-secret.json

podman run --rm -v ${PROJECT_DIR}/${ANSIBLE_DIR}:/runner/project:Z \
  registry.redhat.io/ansible-automation-platform-25/ee-supported-rhel9:latest \
  sh -c "printf \"\nsanity check for folder: ${PROJECT_DIR}/${ANSIBLE_DIR}/secrets\n\" && ls -l ${PROJECT_DIR}/${ANSIBLE_DIR}/secrets/lab"

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
          -v ${PROJECT_DIR}/all-clusters-resources:/runner/all-clusters-resources:Z \
          -v ${PROJECT_DIR}/${ANSIBLE_DIR}/secrets/lab :/runner/project/secrets/lab:Z \
          -v ~/.ansible:/home/runner/.ansible:Z \
          registry.redhat.io/ansible-automation-platform-25/ee-supported-rhel9:latest \
            sh -c "ansible-vault ${action} ${file} \
                  --vault-password-file=${passfile} \
                  --output /runner/project/${output}"
    else
        podman run --rm \
          -v ${PROJECT_DIR}/${ANSIBLE_DIR}:/runner/project:Z \
          -v ${PROJECT_DIR}/all-clusters-resources:/runner/all-clusters-resources:Z \
          -v ${PROJECT_DIR}/${ANSIBLE_DIR}/secrets/lab :/runner/project/secrets/lab:Z \
          -v ~/.ansible:/home/runner/.ansible:Z \
          registry.redhat.io/ansible-automation-platform-25/ee-supported-rhel9:latest \
            sh -c "ansible-vault ${action} ${file} \
                  --vault-password-file=${passfile}"
    fi
}

