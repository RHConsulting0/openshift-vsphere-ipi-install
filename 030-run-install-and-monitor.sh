#!/usr/bin/env bash
#
# 030-run-install-and-monitor.sh - OpenShift Cluster Installation and Monitoring Script
# Complete OpenShift installation with monitoring and kubeconfig management

# Usage function
usage() {
    cat << EOF
Usage: $0 <cluster> <env>

DESCRIPTION:
    Complete OpenShift cluster installation with real-time monitoring and kubeconfig management.
    This script runs the install_and_monitor_cluster.yaml playbook to perform the full cluster
    installation, then validates the installation and manages kubeconfig files.

WORKFLOW:
    1. Validates prerequisites and dependencies
    2. Installs OpenShift cluster with real-time monitoring
    3. Validates cluster installation and health
    4. Manages kubeconfig files and access information
    5. Generates installation and validation summaries
    6. Provides cluster access information

PARAMETERS:
    cluster    Cluster identifier/name (e.g., lab, dev, prod)
    env        Environment identifier (e.g., lab, dev, prod)

EXAMPLES:
    $0 lab lab          # Install lab cluster in lab environment
    $0 dev dev           # Install dev cluster in dev environment
    $0 prod prod         # Install prod cluster in prod environment

PREREQUISITES:
    - Podman must be installed and running
    - Execution environment image 'ocp-provision-ee:latest' must be built
    - Cluster initialization must be completed (020-run-initialize-cluster.sh)
    - Cluster-specific variables must exist in ansible/group_vars/cluster/[cluster]/all.yaml
    - Environment-specific variables must exist in ansible/group_vars/env/[env]/all.yaml
    - Cluster secrets must exist in ansible/secrets/[cluster]/secrets.yaml
    - Vault password file must exist at all-clusters-resources/vault-password.txt
    - install-config.yaml must exist in ansible/install-dir/

CONTAINER INTEGRATION:
    - Uses execution environment container for consistent tooling
    - Automatically mounts project directories with proper SELinux context
    - Provides isolated environment for Ansible operations
    - Runs with root privileges for system-level operations

ANSIBLE CONFIGURATION:
    - Inventory: ansible/inventory.yml
    - Installation Playbook: ansible/install_and_monitor_cluster.yaml
    - Validation Playbook: ansible/validate_cluster_and_kubeconfig.yaml
    - Variables: Cluster, environment, and secrets configurations
    - Vault: Encrypted secrets and sensitive data
    - Verbosity: Maximum verbosity (-vvv) for detailed output

INSTALLATION FEATURES:
    - Real-time progress monitoring
    - Automatic cluster health validation
    - Kubeconfig management and backup
    - Installation summary generation
    - Cluster access information
    - GitOps operator installation (optional)

OPTIONAL FEATURES:
    - GitOps Operator Installation: Set INSTALL_GITOPS=true environment variable
    - Custom monitoring intervals: Configure in playbook variables
    - Extended validation: Additional cluster health checks

SECURITY CONSIDERATIONS:
    - All sensitive data encrypted using Ansible Vault
    - Container provides isolated execution environment
    - Proper SELinux context for file access
    - Vault password file protection
    - Kubeconfig backup for recovery

OPTIONS:
    -h, --help    Show this help message

OUTPUT FILES:
    - 030-install-output.out: Installation process output
    - 030-validation-output.out: Validation process output
    - ansible/install-dir/auth/kubeconfig: Cluster kubeconfig file
    - ansible/kubeconfig-backup/: Kubeconfig backup directory
    - ansible/install-dir/installation-summary.txt: Installation summary
    - ansible/install-dir/cluster-access-info.txt: Cluster access information
    - ansible/install-dir/validation-summary.txt: Validation summary

TROUBLESHOOTING:
    - Ensure cluster initialization was completed successfully
    - Verify all required variable files exist
    - Check vault password file accessibility
    - Review cluster and environment variables
    - Validate install-config.yaml configuration
    - Check vSphere resource availability

RELATED SCRIPTS:
    - This script is standalone and not related to other scripts in this project

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
EXECUTION_CONTAINER="localhost/ocp-provision-ee:latest"

# Project and Ansible directories
PROJECT_DIR="$(pwd)"
ANSIBLE_DIR="ansible"

# Output files
INSTALL_OUTPUT="030-install-output.out"
VALIDATION_OUTPUT="030-validation-output.out"

echo "=========================================="
echo "OpenShift vSphere IPI Installation & Monitoring"
echo "Cluster: $CLUSTER"
echo "Environment: $ENV"
echo "GitOps Installation: ${INSTALL_GITOPS:-false}"
echo "Timestamp: $(date +%Y%m%d%H%M%S)"
echo "=========================================="
echo ""
echo "To enable GitOps operator installation, set:"
echo "export INSTALL_GITOPS=true"
echo ""

# Validate prerequisites
validate_prerequisites() {
    echo "Validating prerequisites..."
    
    # Check if podman is available
    if ! command -v podman &> /dev/null; then
        echo "ERROR: podman is not installed or not in PATH"
        echo "Please install podman and ensure it's available in your PATH"
        exit 1
    fi
    
    # Check if execution environment exists
    if ! podman image exists "$EXECUTION_CONTAINER" 2>/dev/null; then
        echo "ERROR: Execution environment '$EXECUTION_CONTAINER' not found"
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
        echo "ERROR: all-clusters-resources directory not found"
        echo "Please run cluster initialization first: ./020-run-initialize-cluster.sh $CLUSTER $ENV"
        exit 1
    fi
    
    # Check if cluster-specific variables exist
    if [ ! -f "$PROJECT_DIR/$ANSIBLE_DIR/group_vars/cluster/$CLUSTER/all.yaml" ]; then
        echo "ERROR: Cluster variables not found: $PROJECT_DIR/$ANSIBLE_DIR/group_vars/cluster/$CLUSTER/all.yaml"
        echo ""
        echo "Please ensure cluster-specific variables exist for cluster: $CLUSTER"
        exit 1
    fi
    
    # Check if environment-specific variables exist
    if [ ! -f "$PROJECT_DIR/$ANSIBLE_DIR/group_vars/env/$ENV/all.yaml" ]; then
        echo "ERROR: Environment variables not found: $PROJECT_DIR/$ANSIBLE_DIR/group_vars/env/$ENV/all.yaml"
        echo ""
        echo "Please ensure environment-specific variables exist for environment: $ENV"
        exit 1
    fi
    
    # Check if environment default vault exists
    if [ ! -f "$PROJECT_DIR/$ANSIBLE_DIR/group_vars/env/$ENV/default-vault.yaml" ]; then
        echo "ERROR: Environment default vault not found: $PROJECT_DIR/$ANSIBLE_DIR/group_vars/env/$ENV/default-vault.yaml"
        echo ""
        echo "Please ensure environment default vault exists for environment: $ENV"
        exit 1
    fi
    
    # Check if cluster secrets exist
    if [ ! -f "$PROJECT_DIR/$ANSIBLE_DIR/secrets/$CLUSTER/secrets.yaml" ]; then
        echo "ERROR: Cluster secrets not found: $PROJECT_DIR/$ANSIBLE_DIR/secrets/$CLUSTER/secrets.yaml"
        echo ""
        echo "Please ensure cluster secrets exist for cluster: $CLUSTER"
        exit 1
    fi
    
    # Check if vault password file exists
    if [ ! -f "$PROJECT_DIR/all-clusters-resources/vault-password.txt" ]; then
        echo "ERROR: Vault password file not found: $PROJECT_DIR/all-clusters-resources/vault-password.txt"
        echo ""
        echo "Please ensure the vault password file exists"
        exit 1
    fi
    
    # Check if Ansible inventory exists
    if [ ! -f "$PROJECT_DIR/$ANSIBLE_DIR/inventory.yml" ]; then
        echo "ERROR: Ansible inventory not found: $PROJECT_DIR/$ANSIBLE_DIR/inventory.yml"
        echo ""
        echo "Please ensure the Ansible inventory file exists"
        exit 1
    fi
    
    # # Check if install-config.yaml exists
    # if [ ! -f "$PROJECT_DIR/$ANSIBLE_DIR/install-dir/install-config.yaml" ]; then
    #     echo "ERROR: install-config.yaml not found: $PROJECT_DIR/$ANSIBLE_DIR/install-dir/install-config.yaml"
    #     echo ""
    #     echo "Please run cluster initialization first: ./020-run-initialize-cluster.sh $CLUSTER $ENV"
    #     exit 1
    # fi
    
    # Check if installation playbook exists
    if [ ! -f "$PROJECT_DIR/$ANSIBLE_DIR/install_and_monitor_cluster.yaml" ]; then
        echo "ERROR: Installation playbook not found: $PROJECT_DIR/$ANSIBLE_DIR/install_and_monitor_cluster.yaml"
        echo ""
        echo "Please ensure the installation playbook exists"
        exit 1
    fi
    
    # Check if validation playbook exists
    if [ ! -f "$PROJECT_DIR/$ANSIBLE_DIR/validate_cluster_and_kubeconfig.yaml" ]; then
        echo "ERROR: Validation playbook not found: $PROJECT_DIR/$ANSIBLE_DIR/validate_cluster_and_kubeconfig.yaml"
        echo ""
        echo "Please ensure the validation playbook exists"
        exit 1
    fi
    
    echo "Prerequisites validation passed"
}

# Display configuration information
show_configuration() {
    echo "=========================================="
    echo "OpenShift Cluster Installation & Monitoring"
    echo "=========================================="
    echo "Cluster: $CLUSTER"
    echo "Environment: $ENV"
    echo "Execution Container: $EXECUTION_CONTAINER"
    echo "Project Directory: $PROJECT_DIR"
    echo "Ansible Directory: $ANSIBLE_DIR"
    echo "GitOps Installation: ${INSTALL_GITOPS:-false}"
    echo "=========================================="
    echo ""
    
    if [ "${INSTALL_GITOPS:-false}" != "true" ]; then
        echo "To enable GitOps operator installation, set:"
        echo "export INSTALL_GITOPS=true"
        echo ""
    fi
}

# Function to run installation playbook
run_installation() {
    echo "Starting OpenShift cluster installation..."
    echo "This may take 30-60 minutes depending on your infrastructure."
    
    # Check if GitOps installation is enabled
    INSTALL_GITOPS=${INSTALL_GITOPS:-false}
    
    podman run --rm \
      --ipc=host \
      --user=root \
      --group-add=root \
      -v "$PROJECT_DIR/$ANSIBLE_DIR:/runner/project:Z" \
      -v "$PROJECT_DIR/all-clusters-resources:/runner/all-clusters-resources:Z" \
      -v "$PROJECT_DIR/provisioned-clusters:/runner/provisioned-clusters:Z" \
      "$EXECUTION_CONTAINER" \
      ansible-playbook -i /runner/project/inventory.yml \
        -e @/runner/project/group_vars/cluster/${CLUSTER}/all.yaml \
        -e @/runner/project/group_vars/env/${ENV}/default-vault.yaml \
        -e @/runner/project/group_vars/env/${ENV}/all.yaml \
        -e @/runner/project/secrets/${CLUSTER}/secrets.yaml \
        -e install_gitops_operator=${INSTALL_GITOPS} \
        --vault-password-file=/runner/all-clusters-resources/vault-password.txt \
        /runner/project/install_and_monitor_cluster.yaml -vvv
}

# Function to run validation playbook
run_validation() {
    echo "Validating cluster installation and managing kubeconfig..."
    
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
        -e @/runner/project/secrets/${CLUSTER}/secrets.yaml \
        --vault-password-file=/runner/all-clusters-resources/vault-password.txt \
        /runner/project/validate_cluster_and_kubeconfig.yaml -vvv
}

# Function to display results
display_results() {
    echo ""
    echo "=========================================="
    echo "Installation Complete!"
    echo "=========================================="
    
    # Check if installation summary exists
    if [ -f "$ANSIBLE_DIR/install-dir/installation-summary.txt" ]; then
        echo "Installation Summary:"
        cat "$ANSIBLE_DIR/install-dir/installation-summary.txt"
    fi
    
    echo ""
    echo "Cluster Access Information:"
    if [ -f "$ANSIBLE_DIR/install-dir/cluster-access-info.txt" ]; then
        cat "$ANSIBLE_DIR/install-dir/cluster-access-info.txt"
    fi
    
    echo ""
    echo "Next Steps:"
    echo "1. Set KUBECONFIG: export KUBECONFIG=$ANSIBLE_DIR/install-dir/auth/kubeconfig"
    echo "2. Login to cluster: oc login -u kubeadmin -p <password>"
    echo "3. Access console: https://console-openshift-console.apps.$CLUSTER.<base-domain>"
    echo ""
    echo "Note: This script is standalone and completes the cluster installation process."
    echo ""
    echo "Files created:"
    echo "- kubeconfig: $ANSIBLE_DIR/install-dir/auth/kubeconfig"
    echo "- kubeconfig backup: $ANSIBLE_DIR/kubeconfig-backup/"
    echo "- Installation summary: $ANSIBLE_DIR/install-dir/installation-summary.txt"
    echo "- Cluster access info: $ANSIBLE_DIR/install-dir/cluster-access-info.txt"
    echo "- Validation summary: $ANSIBLE_DIR/install-dir/validation-summary.txt"
}

# Main execution
main() {
    # Validate prerequisites
    validate_prerequisites
    
    # Show configuration
    show_configuration
    
    echo "Starting OpenShift cluster installation and monitoring..."
    echo "This process includes installation, validation, and kubeconfig management."
    echo ""
    
    # Run installation with monitoring
    echo "Step 1: Installing and monitoring OpenShift cluster..."
    echo "This may take 30-60 minutes depending on your infrastructure."
    echo ""
    
    if run_installation 2>&1 | tee "$INSTALL_OUTPUT"; then
        echo ""
        echo "=========================================="
        echo "Installation completed successfully!"
        echo "=========================================="
        echo ""
    else
        echo ""
        echo "=========================================="
        echo "ERROR: Installation failed!"
        echo "=========================================="
        echo ""
        echo "Please check the error messages above and resolve any issues."
        echo "Common issues:"
        echo "  - Insufficient vSphere resources"
        echo "  - Network connectivity problems"
        echo "  - Configuration errors in install-config.yaml"
        echo "  - Missing or incorrect variable files"
        echo "  - Vault password or secrets issues"
        echo ""
        echo "Check $INSTALL_OUTPUT for detailed error information."
        echo ""
        echo "Troubleshooting steps:"
        echo "  1. Check vSphere resource availability and permissions"
        echo "  2. Review install-config.yaml configuration"
        echo "  3. Validate all variable files exist and are properly formatted"
        echo "  4. Check vault password file accessibility"
        echo "  5. Verify cluster prerequisites are met"
        echo ""
        exit 1
    fi
    
    # Run validation and kubeconfig management
    echo "Step 2: Validating cluster and managing kubeconfig..."
    echo ""
    
    if run_validation 2>&1 | tee "$VALIDATION_OUTPUT"; then
        echo ""
        echo "=========================================="
        echo "Validation completed successfully!"
        echo "=========================================="
        echo ""
    else
        echo ""
        echo "=========================================="
        echo "ERROR: Validation failed!"
        echo "=========================================="
        echo ""
        echo "Please check the error messages above and resolve any issues."
        echo "Common validation issues:"
        echo "  - Cluster not fully ready"
        echo "  - API server connectivity problems"
        echo "  - Kubeconfig generation issues"
        echo "  - Cluster operator failures"
        echo ""
        echo "Check $VALIDATION_OUTPUT for detailed error information."
        echo ""
        echo "Troubleshooting steps:"
        echo "  1. Wait for cluster to be fully ready (may take additional time)"
        echo "  2. Check cluster operator status"
        echo "  3. Verify API server accessibility"
        echo "  4. Review cluster logs for specific errors"
        echo "  5. Ensure all prerequisites are met"
        echo ""
        exit 1
    fi
    
    # Display results
    display_results
}

# Protect against sourcing – must be run, not sourced.
if [ "${BASH_SOURCE[0]}" != "$0" ]; then
    echo "ERROR: This script must be executed, not sourced."
    echo "Run it like: ./030-run-install-and-monitor.sh lab lab"
    return 1 2>/dev/null || exit 1
fi

# Run main function
main "$@"