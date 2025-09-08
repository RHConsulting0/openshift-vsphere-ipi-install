#!/bin/bash

FILE="secrets/pull_secret_file.yaml"
podman run --rm \
  -v $(pwd):/runner/project:Z \
  -v $(pwd)/resources:/runner/resources:Z \
  registry.redhat.io/ansible-automation-platform-25/ee-supported-rhel9:latest \
  sh -c "ansible-vault view /runner/project/$FILE \
    --vault-password-file=/runner/resources/vault-password.txt \
    > /runner/project/${FILE}.decrypted"

# sanity check
ls -l resources/vault-password.txt
podman run --rm -v "$(pwd)/resources":/runner/resources:Z \
  registry.redhat.io/ansible-automation-platform-25/ee-supported-rhel9:latest \
  ls -l /runner/resources







#ansible-vault decrypt $SECRETS_DIR/pull_secret_file.yaml --vault-password-file=$RESOURCE_DIR/vault-password.txt --output=$SECRETS_DIR/pull_secret_file.yaml.decrypted
#ansible-vault decrypt $SECRETS_DIR/pull_secret.yaml --vault-password-file=$RESOURCE_DIR/vault-password.txt --output=$SECRETS_DIR/pull_secret.yaml.decrypted
#ansible-vault decrypt $SECRETS_DIR/ssh_key.pub --vault-password-file=$RESOURCE_DIR/vault-password.txt --output=$SECRETS_DIR/ssh_key.pub.decrypted




