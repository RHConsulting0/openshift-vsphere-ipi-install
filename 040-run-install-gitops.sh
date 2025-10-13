#!/usr/bin/env bash
#
# 040-run-install-gitops.sh - OpenShift GitOps Operator Installation Script
# Install GitOps operator using operators-installer Helm chart

# Usage function
usage() {
    cat << EOF
Usage: $0 <cluster> <env>

DESCRIPTION:
    Install OpenShift GitOps operator using the operators-installer Helm chart.
    This script runs the install_gitops_operator.yaml playbook to deploy the
    OpenShift GitOps operator and ArgoCD instance for GitOps-based application delivery.

WORKFLOW:
    1. Validates prerequisites and cluster connectivity
    2. Checks Helm availability in execution environment
    3. Installs OpenShift GitOps operator using Helm chart
    4. Configures ArgoCD instance and routes
    5. Verifies installation and operator status
    6. Provides access information and next steps

PARAMETERS:
    cluster    Cluster identifier/name (e.g., lab, dev, prod)
    env        Environment identifier (e.g., lab, dev, prod)

EXAMPLES:
    $0 lab lab          # Install GitOps operator on lab cluster
    $0 dev dev           # Install GitOps operator on dev cluster
    $0 prod prod         # Install GitOps operator on prod cluster

PREREQUISITES:
    - Podman must be installed and running
    - Execution environment image 'ocp-provision-ee:latest' must be built
    - Cluster installation must be completed (030-run-install-and-monitor.sh)
    - Cluster must be accessible via kubeconfig
    - Cluster-specific variables must exist in ansible/group_vars/cluster/[cluster]/all.yaml
    - Environment-specific variables must exist in ansible/group_vars/env/[env]/all.yaml
    - Cluster secrets must exist in ansible/secrets/[cluster]/secrets.yaml
    - Vault password file must exist at all-clusters-resources/vault-password.txt

CONTAINER INTEGRATION:
    - Uses execution environment container for consistent tooling
    - Automatically mounts project directories with proper SELinux context
    - Mounts kubeconfig for cluster access
    - Provides isolated environment for Ansible operations
    - Runs with root privileges for system-level operations

ANSIBLE CONFIGURATION:
    - Inventory: ansible/inventory.yml
    - Playbook: ansible/install_gitops_operator.yaml
    - Variables: Cluster, environment, and secrets configurations
    - Vault: Encrypted secrets and sensitive data
    - Verbosity: Maximum verbosity (-vvv) for detailed output

HELM INTEGRATION:
    - Uses operators-installer Helm chart from redhat-cop repository
    - Installs OpenShift GitOps operator in openshift-gitops namespace
    - Configures ArgoCD instance with default settings
    - Creates necessary routes and services

INSTALLATION FEATURES:
    - OpenShift GitOps operator installation
    - ArgoCD instance configuration
    - Route creation for web console access
    - Operator subscription management
    - Installation verification and status checks

SECURITY CONSIDERATIONS:
    - All sensitive data encrypted using Ansible Vault
    - Container provides isolated execution environment
    - Proper SELinux context for file access
    - Vault password file protection
    - Kubeconfig mounted securely

OPTIONS:
    -h, --help    Show this help message

OUTPUT FILES:
    - 040-gitops-output.out: Installation process output
    - ansible/gitops-installation-summary.txt: Installation summary
    - ansible/templates/gitops-operator-values.yaml: Helm values file

VERIFICATION:
    - Operator subscription status
    - ArgoCD instance health
    - Pod status in openshift-gitops namespace
    - Route accessibility

TROUBLESHOOTING:
    - Ensure cluster installation was completed successfully
    - Verify cluster connectivity and kubeconfig validity
    - Check Helm availability in execution environment
    - Review operator subscription status
    - Validate ArgoCD instance configuration

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
EXECUTION_CONTAINER="ocp-provision-ee:latest"

# Project and Ansible directories
PROJECT_DIR="$(pwd)"
ANSIBLE_DIR="ansible"

# Output files
GITOPS_OUTPUT="040-gitops-output.out"

echo "=========================================="
echo "GitOps Operator Installation"
echo "Cluster: $CLUSTER"
echo "Environment: $ENV"
echo "=========================================="

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
        echo "Please ensure cluster prerequisites are met"
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
    
    # Check if GitOps installation playbook exists
    if [ ! -f "$PROJECT_DIR/$ANSIBLE_DIR/install_gitops_operator.yaml" ]; then
        echo "ERROR: GitOps installation playbook not found: $PROJECT_DIR/$ANSIBLE_DIR/install_gitops_operator.yaml"
        echo ""
        echo "Please ensure the GitOps installation playbook exists"
        exit 1
    fi
    
    echo "Prerequisites validation passed"
}

# Check cluster connectivity
check_cluster_access() {
    echo "Checking cluster connectivity..."
    
    # Check if kubeconfig exists
    if [ ! -f "$PROJECT_DIR/$ANSIBLE_DIR/install-dir/auth/kubeconfig" ]; then
        echo "ERROR: kubeconfig not found at $PROJECT_DIR/$ANSIBLE_DIR/install-dir/auth/kubeconfig"
        echo ""
        echo "Please ensure cluster prerequisites are met and kubeconfig is available"
        exit 1
    fi
    
    # Test cluster connectivity using execution environment
    echo "Testing cluster connectivity..."
    podman run --rm \
      --ipc=host \
      --user=root \
      --group-add=root \
      -v "$PROJECT_DIR/$ANSIBLE_DIR:/runner/project:Z" \
      -v "$PROJECT_DIR/all-clusters-resources:/runner/all-clusters-resources:Z" \
      -v "$PROJECT_DIR/$ANSIBLE_DIR/install-dir/auth/kubeconfig:/root/.kube/config:Z" \
      "$EXECUTION_CONTAINER" \
      oc cluster-info &> /dev/null
      
    if [ $? -ne 0 ]; then
        echo "ERROR: Cannot connect to cluster"
        echo ""
        echo "Please check:"
        echo "  1. Cluster is running and accessible"
        echo "  2. kubeconfig is valid and not expired"
        echo "  3. Network connectivity to cluster API server"
        echo "  4. Cluster prerequisites are met"
        exit 1
    fi
    
    echo "Cluster connectivity verified"
}

# Check Helm availability
check_helm_availability() {
    echo "Checking Helm availability in execution environment..."
    
    # Check if Helm is available in execution environment
    podman run --rm \
      --ipc=host \
      --user=root \
      --group-add=root \
      -v "$PROJECT_DIR/$ANSIBLE_DIR:/runner/project:Z" \
      -v "$PROJECT_DIR/all-clusters-resources:/runner/all-clusters-resources:Z" \
      "$EXECUTION_CONTAINER" \
      helm version --short &> /dev/null
      
    if [ $? -ne 0 ]; then
        echo "ERROR: Helm not available in execution environment"
        echo ""
        echo "Please ensure Helm is installed in the execution environment:"
        echo "  cd automation-ee/ocp-provision-ee/"
        echo "  ./builder.sh"
        echo ""
        exit 1
    fi
    
    echo "Helm availability verified"
}

# Display configuration information
show_configuration() {
    echo "=========================================="
    echo "GitOps Operator Installation"
    echo "=========================================="
    echo "Cluster: $CLUSTER"
    echo "Environment: $ENV"
    echo "Execution Container: $EXECUTION_CONTAINER"
    echo "Project Directory: $PROJECT_DIR"
    echo "Ansible Directory: $ANSIBLE_DIR"
    echo "Kubeconfig: $ANSIBLE_DIR/install-dir/auth/kubeconfig"
    echo "=========================================="
    echo ""
}

# Function to run GitOps installation
run_gitops_installation() {
    echo "Starting GitOps operator installation..."
    echo "This will install the OpenShift GitOps operator using the operators-installer Helm chart"
    
    podman run --rm \
      --ipc=host \
      --user=root \
      --group-add=root \
      -v "$PROJECT_DIR/$ANSIBLE_DIR:/runner/project:Z" \
      -v "$PROJECT_DIR/all-clusters-resources:/runner/all-clusters-resources:Z" \
      -v "$PROJECT_DIR/$ANSIBLE_DIR/install-dir/auth/kubeconfig:/root/.kube/config:Z" \
      -v "$PROJECT_DIR/day2:/runner/day2:Z" \
      "$EXECUTION_CONTAINER" \
      ansible-playbook -i /runner/project/inventory.yml \
        -e @/runner/project/group_vars/cluster/${CLUSTER}/all.yaml \
        -e @/runner/project/group_vars/env/${ENV}/default-vault.yaml \
        -e @/runner/project/group_vars/env/${ENV}/all.yaml \
        -e @/runner/project/secrets/${CLUSTER}/secrets.yaml \
        --vault-password-file=/runner/all-clusters-resources/vault-password.txt \
        /runner/project/init_gitops.yaml -vvv
}


run_gitops_installationORIG() {
    echo "Starting GitOps operator installation..."
    echo "This will install the OpenShift GitOps operator using the operators-installer Helm chart"
    
    podman run --rm \
      --ipc=host \
      --user=root \
      --group-add=root \
      -v "$PROJECT_DIR/$ANSIBLE_DIR:/runner/project:Z" \
      -v "$PROJECT_DIR/all-clusters-resources:/runner/all-clusters-resources:Z" \
      -v "$PROJECT_DIR/$ANSIBLE_DIR/install-dir/auth/kubeconfig:/root/.kube/config:Z" \
      "$EXECUTION_CONTAINER" \
      ansible-playbook -i /runner/project/inventory.yml \
        -e @/runner/project/group_vars/cluster/${CLUSTER}/all.yaml \
        -e @/runner/project/group_vars/env/${ENV}/default-vault.yaml \
        -e @/runner/project/group_vars/env/${ENV}/all.yaml \
        -e @/runner/project/secrets/${CLUSTER}/secrets.yaml \
        --vault-password-file=/runner/all-clusters-resources/vault-password.txt \
        /runner/project/install_gitops_operator.yaml -vvv
}

# Function to display results
display_results() {
    echo ""
    echo "=========================================="
    echo "GitOps Installation Complete!"
    echo "=========================================="
    
    # Check if installation summary exists
    if [ -f "$ANSIBLE_DIR/gitops-installation-summary.txt" ]; then
        echo "Installation Summary:"
        cat "$ANSIBLE_DIR/gitops-installation-summary.txt"
    fi
    
    echo ""
    echo "Next Steps:"
    echo "1. Access ArgoCD console using the URL provided above"
    echo "2. Login with the admin credentials"
    echo "3. Configure Git repositories"
    echo "4. Deploy applications using GitOps"
    echo ""
    echo "Note: This script is standalone and completes the GitOps operator installation."
    echo ""
    echo "Files created:"
    echo "- Installation summary: $ANSIBLE_DIR/gitops-installation-summary.txt"
    echo "- Values file: $ANSIBLE_DIR/templates/gitops-operator-values.yaml"
    echo ""
    echo "Useful commands:"
    echo "- Check operator status: oc get subscription -n openshift-gitops"
    echo "- Check ArgoCD pods: oc get pods -n openshift-gitops"
    echo "- Get ArgoCD route: oc get route -n openshift-gitops"
}

# Function to verify installation
verify_installation() {
    echo "Verifying GitOps installation..."
    
    export KUBECONFIG="$ANSIBLE_DIR/install-dir/auth/kubeconfig"
    
    # Check operator subscription
    echo "Checking operator subscription..."
    oc get subscription openshift-gitops-operator -n openshift-gitops-operator
    
    # Check ArgoCD instance
    echo "Checking ArgoCD instance..."
    oc get argocd -n openshift-gitops
    
    # Check ArgoCD pods
    echo "Checking ArgoCD pods..."
    oc get pods -n openshift-gitops
    
    # Check ArgoCD route
    echo "Checking ArgoCD route..."
    oc get route -n openshift-gitops
    
    echo "Verification complete"
}

# Main execution
main() {
    # Validate prerequisites
    validate_prerequisites
    
    # Check cluster connectivity
    check_cluster_access
    
    # Check Helm availability
    check_helm_availability
    
    # Show configuration
    show_configuration
    
    echo "Starting GitOps operator installation..."
    echo "This will install the OpenShift GitOps operator and ArgoCD instance."
    echo ""
    
    # Run GitOps installation
    echo "Installing GitOps operator using Helm chart..."
    if run_gitops_installation 2>&1 | tee "$GITOPS_OUTPUT"; then
        echo ""
        echo "=========================================="
        echo "GitOps installation completed successfully!"
        echo "=========================================="
        echo ""
    else
        echo ""
        echo "=========================================="
        echo "ERROR: GitOps installation failed!"
        echo "=========================================="
        echo ""
        echo "Please check the error messages above and resolve any issues."
        echo "Common issues:"
        echo "  - Cluster not accessible or not ready"
        echo "  - Helm chart repository issues"
        echo "  - Operator subscription problems"
        echo "  - Insufficient cluster resources"
        echo "  - Network connectivity issues"
        echo ""
        echo "Check $GITOPS_OUTPUT for detailed error information."
        echo ""
        echo "Troubleshooting steps:"
        echo "  1. Check cluster connectivity and kubeconfig validity"
        echo "  2. Ensure Helm is available in execution environment"
        echo "  3. Review operator subscription status"
        echo "  4. Check cluster resource availability"
        echo "  5. Verify cluster prerequisites are met"
        echo ""
        exit 1
    fi
    
    # Verify installation
    echo "Verifying GitOps installation..."
    verify_installation
    
    # Display results
    display_results
}

# Protect against sourcing – must be run, not sourced.
if [ "${BASH_SOURCE[0]}" != "$0" ]; then
    echo "ERROR: This script must be executed, not sourced."
    echo "Run it like: ./040-run-install-gitops.sh lab lab"
    return 1 2>/dev/null || exit 1
fi

# Run main function
main "$@"