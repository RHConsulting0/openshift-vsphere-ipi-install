#!/bin/bash

# sanity check for folders: /runner/project && /runner/resources
podman run --rm \
  -v $(pwd):/runner/project:Z \
  -v $(pwd)/resources:/runner/resources:Z \
  registry.redhat.io/ansible-automation-platform-25/ee-supported-rhel9:latest \
  sh -c "printf \"sanity check for folder: /runner/project\n\" && ls -l /runner/project && printf \"sanity check for folder: /runner/resources\n\" && ls -l /runner/resources"

FILE="ansible/secrets/pull-secret.json"
printf "Podman...\n"
podman run --rm \
  -v $(pwd):/runner/project:Z \
  -v $(pwd)/resources:/runner/resources:Z \
  registry.redhat.io/ansible-automation-platform-25/ee-supported-rhel9:latest \
  sh -c "ansible-vault view /runner/project/${FILE} \
    --vault-password-file=/runner/resources/vault-password.txt \
    > /runner/project/${FILE}.decrypted"

# sanity check for folder: /runner/project/ansible/secrets
printf "sanity check for local folder: $(pwd)/ansible/secrets\n"
ls -l $FILE
printf "Podman...\n"
podman run --rm -v $(pwd):/runner/project:Z \
  registry.redhat.io/ansible-automation-platform-25/ee-supported-rhel9:latest \
  sh -c "printf \"sanity check for folder: /runner/project/ansible/secrets\n\" && ls -l /runner/project/ansible/secrets"


