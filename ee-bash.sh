#!/bin/bash

PROJECT_DIR="/home/miryan/Documents/projects/odfl/repos/openshift-vsphere-ipi-install"
ANSIBLE_DIR="ansible"


podman run --rm -it \
  -v ${PROJECT_DIR}/${ANSIBLE_DIR}:/runner/project:Z \
  -v ${PROJECT_DIR}/resources:/runner/resources:Z \
  -v ~/.ansible:/home/runner/.ansible:Z \
  registry.redhat.io/ansible-automation-platform-25/ee-supported-rhel9:latest /bin/bash
