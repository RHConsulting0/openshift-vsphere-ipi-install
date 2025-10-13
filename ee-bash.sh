#!/bin/bash

# Ansible expects yaml for encrypted files
# https://docs.ansible.com/ansible/latest/user_guide/vault.html 
# https://docs.ansible.com/ansible/latest/collections/ansible/builtin/vault_module.html

# Usage function
usage() {
    cat << EOF
Usage: $0 <cluster> <env> [OPTIONS]

DESCRIPTION:
    Launch an Ansible Execution Environment (EE) container for OpenShift cluster provisioning.
    Provides an interactive bash shell with all necessary tools for OpenShift installation.
    This script launches a containerized environment with all required tools pre-installed.

PARAMETERS:
    cluster    Cluster identifier/name (e.g., lab, prod, dev)
    env        Environment identifier (e.g., lab, prod, dev)

CONTAINER FEATURES:
    - OpenShift installer tools (openshift-install, oc, kubectl)
    - Helm v3.16.3, Kustomize v5.5.0, Policy Generator v1.15.0
    - Ansible with required collections
    - Corporate certificates and configurations
    - Volume mounts: ./ansible/ and ./all-clusters-resources/

WORKING INSIDE CONTAINER:
    cd /runner/project                    # Navigate to ansible directory
    ansible-playbook install_and_monitor_cluster.yaml  # Run playbooks
    openshift-install version             # Check OpenShift tools
    oc get nodes                          # Check cluster status
    helm list                             # List Helm releases

PREREQUISITES:
    - Podman must be installed and running
    - Execution environment image 'ocp-provision-ee:latest' must be built
    - Run './automation-ee/ocp-provision-ee/builder.sh' to build the EE image

EXAMPLES:
    $0 lab lab              # Launch EE container for lab cluster in lab environment
    $0 prod prod            # Launch EE container for prod cluster in prod environment
    $0 dev dev              # Launch EE container for dev cluster in dev environment
    $0 --help               # Show this help message

OPTIONS:
    -h, --help    Show this help message

EOF
}

# Check for help option
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    usage
    exit 0
fi

# Check for required parameters
if [[ $# -lt 2 ]]; then
    echo "ERROR: Missing required parameters"
    echo ""
    usage
    exit 1
fi

# Store parameters
CLUSTER="$1"
ENV="$2"

# Validate parameters (basic validation)
if [[ -z "$CLUSTER" || -z "$ENV" ]]; then
    echo "ERROR: Both cluster and environment parameters are required"
    echo ""
    usage
    exit 1
fi

# Container execution environment
#EXECUTION_CONTAINER="registry.redhat.io/ansible-automation-platform-25/ee-supported-rhel9:latest"
EXECUTION_CONTAINER="ocp-provision-ee:latest"

# Project and Ansible directories
PROJECT_DIR="$(pwd)"
ANSIBLE_DIR="ansible"

# Check if execution environment image exists
if ! podman image exists "$EXECUTION_CONTAINER" 2>/dev/null; then
    echo "ERROR: Execution environment image '$EXECUTION_CONTAINER' not found"
    echo ""
    echo "To build the execution environment, run:"
    echo "  cd automation-ee/ocp-provision-ee/"
    echo "  ./builder.sh"
    echo ""
    exit 1
fi

# Check if required directories exist
if [ ! -d "$PROJECT_DIR/$ANSIBLE_DIR" ]; then
    echo "ERROR: Ansible directory '$ANSIBLE_DIR' not found in current directory"
    echo "Current directory: $PROJECT_DIR"
    exit 1
fi

if [ ! -d "$PROJECT_DIR/all-clusters-resources" ]; then
    echo "WARNING: all-clusters-resources directory not found"
    echo "Creating directory: $PROJECT_DIR/all-clusters-resources"
    mkdir -p "$PROJECT_DIR/all-clusters-resources"
fi

# Display startup information
echo "=========================================="
echo "Ansible Execution Environment Launcher"
echo "=========================================="
echo "Execution Container: $EXECUTION_CONTAINER"
echo "Project Directory: $PROJECT_DIR"
echo "Cluster: $CLUSTER"
echo "Environment: $ENV"
echo "=========================================="
echo ""

# Run the Ansible playbook in a container
printf "Starting Podman container...\n"
podman run --rm -it \
  --ipc=host \
  --user=root \
  --group-add=root \
  -e CLUSTER="$CLUSTER" \
  -e ENV="$ENV" \
  -v "$PROJECT_DIR/$ANSIBLE_DIR:/runner/project:Z" \
  -v "$PROJECT_DIR/all-clusters-resources:/runner/all-clusters-resources:Z" \
  -v "$PROJECT_DIR/day2:/runner/day2:Z" \
  "$EXECUTION_CONTAINER"


