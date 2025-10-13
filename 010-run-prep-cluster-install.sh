#!/usr/bin/env bash
#
# 010-run-prep-cluster-install.sh - OpenShift Cluster Preparation Script
# Protect against sourcing – must be run, not sourced.

# Usage function
usage() {
    cat << EOF
Usage: $0 <cluster> <env>

DESCRIPTION:
    Prepare OpenShift cluster environment and validate prerequisites before installation.
    This script runs the prep_cluster_install.yaml playbook to set up the cluster environment,
    validate configurations, and prepare necessary resources for cluster installation.

WORKFLOW:
    1. Validates prerequisites and dependencies
    2. Prepares cluster-specific configurations
    3. Sets up required directories and files
    4. Validates Ansible inventory and variables
    5. Prepares secrets and certificates
    6. Creates necessary cluster resources

PARAMETERS:
    cluster    Cluster identifier/name (e.g., lab, dev, prod)
    env        Environment identifier (e.g., lab, dev, prod)

EXAMPLES:
    $0 lab lab          # Prepare lab cluster in lab environment
    $0 dev dev           # Prepare dev cluster in dev environment
    $0 prod prod         # Prepare prod cluster in prod environment

PREREQUISITES:
    - Podman must be installed and running
    - Execution environment image 'ocp-provision-ee:latest' must be built
    - Cluster-specific variables must exist in ansible/group_vars/cluster/[cluster]/all.yaml
    - Environment-specific variables must exist in ansible/group_vars/env/[env]/all.yaml
    - Vault password file must exist at all-clusters-resources/vault-password.txt
    - Pull secret must exist at all-clusters-resources/pull-secret.json

CONTAINER INTEGRATION:
    - Uses execution environment container for consistent tooling
    - Automatically mounts project directories with proper SELinux context
    - Provides isolated environment for Ansible operations
    - Runs with root privileges for system-level operations

ANSIBLE CONFIGURATION:
    - Inventory: ansible/inventory.yml
    - Playbook: ansible/prep_cluster_install.yaml
    - Variables: Cluster and environment-specific configurations
    - Vault: Encrypted secrets and sensitive data
    - Verbosity: Maximum verbosity (-vvv) for detailed output

SECURITY CONSIDERATIONS:
    - All sensitive data encrypted using Ansible Vault
    - Container provides isolated execution environment
    - Proper SELinux context for file access
    - Vault password file protection

OPTIONS:
    -h, --help    Show this help message

OUTPUT:
    - Detailed preparation steps with timestamps
    - Validation results for all prerequisites
    - Configuration verification status
    - Resource preparation confirmation

TROUBLESHOOTING:
    - Ensure all required variable files exist
    - Verify execution environment image is built
    - Check vault password file accessibility
    - Review Ansible inventory configuration
    - Validate cluster and environment variables

RELATED SCRIPTS:
    - 020-run-initialize-cluster.sh: Cluster initialization (prerequisite: this script must run first)

EOF
}

# Check for help option
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    usage
    exit 0
fi

# Validate parameters
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "ERROR: Missing required parameters"
    echo ""
    usage
    exit 1
fi

CLUSTER=$1
ENV=$2

# Container execution environment
# This script creates the secrets Ansible Vault      
#EXECUTION_CONTAINER="registry.redhat.io/ansible-automation-platform-25/ee-supported-rhel9:latest"
EXECUTION_CONTAINER="localhost/ocp-provision-ee:latest"

# Project and Ansible directories
PROJECT_DIR="$(pwd)"
ANSIBLE_DIR="ansible"

# Validate prerequisites
validate_prerequisites() {
    echo "Validating prerequisites..."
    
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
    
    # Check if cluster-specific variables exist
    if [ ! -f "$PROJECT_DIR/$ANSIBLE_DIR/group_vars/cluster/$CLUSTER/all.yaml" ]; then
        echo "ERROR: Cluster variables not found: $PROJECT_DIR/$ANSIBLE_DIR/group_vars/cluster/$CLUSTER/all.yaml"
        echo ""
        echo "Please ensure cluster-specific variables exist for cluster: $CLUSTER"
        echo "Use ansible/group_vars/cluster/dev/all.yaml as an example"
        exit 1
    fi
    
    # Check if environment-specific variables exist
    if [ ! -f "$PROJECT_DIR/$ANSIBLE_DIR/group_vars/env/$ENV/all.yaml" ]; then
        echo "ERROR: Environment variables not found: $PROJECT_DIR/$ANSIBLE_DIR/group_vars/env/$ENV/all.yaml"
        echo ""
        echo "Please ensure environment-specific variables exist for environment: $ENV"
        exit 1
    fi
    
    # Check if vault password file exists
    if [ ! -f "$PROJECT_DIR/all-clusters-resources/vault-password.txt" ]; then
        echo "ERROR: Vault password file not found: $PROJECT_DIR/all-clusters-resources/vault-password.txt"
        echo ""
        echo "Please ensure the vault password file exists"
        exit 1
    fi
    
    # Check if pull secret exists
    if [ ! -f "$PROJECT_DIR/all-clusters-resources/pull-secret.json" ]; then
        echo "ERROR: Pull secret file not found: $PROJECT_DIR/all-clusters-resources/pull-secret.json"
        echo ""
        echo "Please ensure the pull secret file exists"
        exit 1
    fi
    
    # Check if Ansible inventory exists
    if [ ! -f "$PROJECT_DIR/$ANSIBLE_DIR/inventory.yml" ]; then
        echo "ERROR: Ansible inventory not found: $PROJECT_DIR/$ANSIBLE_DIR/inventory.yml"
        echo ""
        echo "Please ensure the Ansible inventory file exists"
        exit 1
    fi
    
    # Check if prep playbook exists
    if [ ! -f "$PROJECT_DIR/$ANSIBLE_DIR/prep_cluster_install.yaml" ]; then
        echo "ERROR: Preparation playbook not found: $PROJECT_DIR/$ANSIBLE_DIR/prep_cluster_install.yaml"
        echo ""
        echo "Please ensure the preparation playbook exists"
        exit 1
    fi
    
    echo "Prerequisites validation passed"
}

# Display configuration information
show_configuration() {
    echo "=========================================="
    echo "OpenShift Cluster Preparation"
    echo "=========================================="
    echo "Cluster: $CLUSTER"
    echo "Environment: $ENV"
    echo "Execution Container: $EXECUTION_CONTAINER"
    echo "Project Directory: $PROJECT_DIR"
    echo "Ansible Directory: $ANSIBLE_DIR"
    echo "=========================================="
    echo ""
}

# Main execution
main() {
    # Validate prerequisites
    validate_prerequisites
    
    # Show configuration
    show_configuration
    
    echo "Starting cluster preparation..."
    echo "This will prepare the cluster environment and validate all prerequisites."
    echo ""
    
    # Run the Ansible playbook in a container
    printf "Podman container starting...\n"
    podman run --rm \
      --ipc=host \
      --user=root \
      --group-add=root \
      -v "$PROJECT_DIR/$ANSIBLE_DIR:/runner/project:Z" \
      -v "$PROJECT_DIR/all-clusters-resources:/runner/all-clusters-resources:Z" \
      "$EXECUTION_CONTAINER" \
      ansible-playbook -i /runner/project/inventory.yml \
        -e @/runner/project/group_vars/cluster/${CLUSTER}/all.yaml \
        -e @/runner/project/group_vars/env/${ENV}/default-vault.yaml \
        -e @/runner/project/group_vars/env/${ENV}/all.yaml \
        -e @/runner/all-clusters-resources/pull-secret.json \
        --vault-password-file=/runner/all-clusters-resources/vault-password.txt \
        /runner/project/prep_cluster_install.yaml -vvv
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "=========================================="
        echo "Cluster preparation completed successfully!"
        echo "=========================================="
        echo ""
        echo "Next steps:"
        echo "  1. Run: ./020-run-initialize-cluster.sh $CLUSTER $ENV"
        echo ""
    else
        echo ""
        echo "=========================================="
        echo "Cluster preparation failed!"
        echo "=========================================="
        echo ""
        echo "Please check the error messages above and resolve any issues."
        echo "Common issues:"
        echo "  - Missing or incorrect variable files"
        echo "  - Vault password or pull secret issues"
        echo "  - Network connectivity problems"
        echo "  - Insufficient permissions"
        echo ""
        exit 1
    fi
}

# Protect against sourcing – must be run, not sourced.
if [ "${BASH_SOURCE[0]}" != "$0" ]; then
    echo "ERROR: This script must be executed, not sourced."
    echo "Run it like: ./010-run-prep-cluster-install.sh lab lab"
    return 1 2>/dev/null || exit 1
fi

# Run main function
main


