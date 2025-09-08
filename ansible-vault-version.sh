#!/bin/bash



podman run --rm \
  -v $(pwd):/runner/project:Z \
  -v $(pwd)/resources:/runner/resources:Z \
  registry.redhat.io/ansible-automation-platform-25/ee-supported-rhel9:latest \
  sh -c "ansible-vault --version"
