#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

INSTALL_DIR=../ansible/install-dir

# Function to print messages with timestamp and color
log() {
    local color=$1
    local msg=$2
    printf "%s %b%s%b\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$color" "$msg" "$NC"
}

log $YELLOW "Listing install directory contents:"
ls -lta "$INSTALL_DIR"

log $YELLOW "Copying original install-config.yaml to install-dir..."
cp "$INSTALL_DIR/install-config.yaml.orig" ./install-dir/install-config.yaml
log $GREEN "install-config.yaml copied successfully"

log $YELLOW "Creating OpenShift manifests..."
openshift-install create manifests --dir=./install-dir
log $GREEN "Manifests created successfully"

log $GREEN "All steps completed successfully! 🎉"
