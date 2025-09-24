#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Directories for manifests and test
INSTALL_DIR=../ansible/install-dir                # Directory containing install-config.yaml.orig

TEST_INSTALL_DIR=./install-dir
CLUSTER_API_DIR=$TEST_INSTALL_DIR/cluster-api
MANIFEST_DIR=$TEST_INSTALL_DIR/manifests
OPENSHIFT_DIR=$TEST_INSTALL_DIR/openshift

# Execution container
EXECUTION_CONTAINER="ocp-provision-ee:latest"

# Function to print messages with timestamp and color
log() {
    local color=$1
    local msg=$2
    printf "%s %b%s%b\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$color" "$msg" "$NC"
}

log $YELLOW "\nListing cluster provision install directory contents: [${INSTALL_DIR}]"
ls -lta "$INSTALL_DIR"

printf "\n"
log $YELLOW "Cleaning up old manifests..."

log $YELLOW "  Cleaning [${MANIFEST_DIR}]..."
rm -fv $MANIFEST_DIR/*.yml
rm -fv $MANIFEST_DIR/*.yaml

log $YELLOW "  Cleaning [${OPENSHIFT_DIR}]..."
rm -fv $OPENSHIFT_DIR/*.yaml
rm -fv $OPENSHIFT_DIR/*.yml

log $YELLOW "  Cleaning [${CLUSTER_API_DIR}]..."
rm -fv $CLUSTER_API_DIR/*.yaml
rm -fv $CLUSTER_API_DIR/*.yml

printf "\n"
log $YELLOW "Viewing [${TEST_INSTALL_DIR}]"
ls -ltaR $TEST_INSTALL_DIR
printf "\n"
log $GREEN "Old manifests cleaned up successfully"

log $YELLOW "Copying install-config.yaml.orig to install-dir..."
cp "$INSTALL_DIR/install-config.yaml.orig" "$TEST_INSTALL_DIR/install-config.yaml"
log $GREEN "install-config.yaml copied successfully"

log $YELLOW "Creating OpenShift manifests..."
# openshift-install create manifests --dir=./install-dir
log $YELLOW "  Podman container starting...\n"
podman run --rm \
  --ipc=host \
  --user=root \
  --group-add=root \
  -v $TEST_INSTALL_DIR:/runner/project:Z \
  $EXECUTION_CONTAINER openshift-install create manifests --dir=/runner/project

log $GREEN "Manifests created successfully"

log $GREEN "All steps completed successfully! 🎉"
