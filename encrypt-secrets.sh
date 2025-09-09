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


pull_secret.json






vault_podman() {
    local action="$1"       # encrypt, decrypt, or view
    local file="$2"         # path to file
    local passfile="$3"     # vault password file path
    local output="$4"       # optional output file

    if [ -n "$output" ]; then
        podman run --rm \
            -v "$(pwd)":/runner/project:Z \
            -v "$(realpath "$passfile")":/runner/vault-pass.txt:Z \
            registry.redhat.io/ansible-automation-platform-25/ee-supported-rhel9:latest \
            sh -c "ansible-vault view /runner/project/$file \
                   --vault-password-file /runner/vault-pass.txt \
                   > /runner/project/$output"
    else
        podman run --rm \
            -v "$(pwd)":/runner/project:Z \
            -v "$(realpath "$passfile")":/runner/vault-pass.txt:Z \
            registry.redhat.io/ansible-automation-platform-25/ee-supported-rhel9:latest \
            sh -c "ansible-vault $action /runner/project/$file \
                   --vault-password-file /runner/vault-pass.txt"
    fi
}

