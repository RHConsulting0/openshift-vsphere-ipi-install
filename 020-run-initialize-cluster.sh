#!/usr/bin/env bash
#
# 020-run-initialize-cluster.sh - OpenShift Cluster Initialization Script
# Protect against sourcing – must be run, not sourced.

# Usage function
usage() {
    cat << EOF
Usage: $0 <cluster> <env>

DESCRIPTION:
    Initialize OpenShift cluster configuration and create install-config.yaml.
    This script runs the initialize_cluster.yaml playbook to generate the cluster
    configuration file from templates and prepare the cluster for installation.

WORKFLOW:
    1. Validates prerequisites and dependencies
    2. Generates install-config.yaml from templates
    3. Configures cluster-specific variables
    4. Prepares installation directory structure
    5. Validates configuration before installation
    6. Creates backup of original configuration

PARAMETERS:
    cluster    Cluster identifier/name (e.g., lab, dev, prod)
    env        Environment identifier (e.g., lab, dev, prod)

EXAMPLES:
    $0 lab lab          # Initialize lab cluster in lab environment
    $0 dev dev           # Initialize dev cluster in dev environment
    $0 prod prod         # Initialize prod cluster in prod environment

PREREQUISITES:
    - Podman must be installed and running
    - Execution environment image 'ocp-provision-ee:latest' must be built
    - Cluster preparation must be completed (010-run-prep-cluster-install.sh)
    - Cluster-specific variables must exist in ansible/group_vars/cluster/[cluster]/all.yaml
    - Environment-specific variables must exist in ansible/group_vars/env/[env]/all.yaml
    - Cluster secrets must exist in ansible/secrets/[cluster]/secrets.yaml
    - Vault password file must exist at all-clusters-resources/vault-password.txt

CONTAINER INTEGRATION:
    - Uses execution environment container for consistent tooling
    - Automatically mounts project directories with proper SELinux context
    - Provides isolated environment for Ansible operations
    - Runs with root privileges for system-level operations

ANSIBLE CONFIGURATION:
    - Inventory: ansible/inventory.yml
    - Playbook: ansible/initialize_cluster.yaml
    - Variables: Cluster, environment, and secrets configurations
    - Vault: Encrypted secrets and sensitive data
    - Verbosity: Maximum verbosity (-vvv) for detailed output

OUTPUT FILES:
    - ansible/install-dir/install-config.yaml: Generated cluster configuration
    - ansible/install-dir/install-config.yaml.orig: Backup of original configuration
    - ansible/install-dir/: Complete installation directory structure

SECURITY CONSIDERATIONS:
    - All sensitive data encrypted using Ansible Vault
    - Container provides isolated execution environment
    - Proper SELinux context for file access
    - Vault password file protection
    - Configuration backup for recovery

OPTIONS:
    -h, --help    Show this help message

OUTPUT:
    - Detailed initialization steps with timestamps
    - Configuration generation status
    - Template processing results
    - Directory structure creation
    - Configuration validation results

TROUBLESHOOTING:
    - Ensure cluster preparation was completed successfully
    - Verify all required variable files exist
    - Check vault password file accessibility
    - Review cluster and environment variables
    - Validate template configurations

RELATED SCRIPTS:
    - 010-run-prep-cluster-install.sh: Cluster preparation (prerequisite: must run first)

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
#EXECUTION_CONTAINER="registry.redhat.io/ansible-automation-platform-25/ee-supported-rhel9:latest"

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
        echo "ERROR: all-clusters-resources directory not found"
        echo "Please run cluster preparation first: ./010-run-prep-cluster-install.sh $CLUSTER $ENV"
        exit 1
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
        echo "This file should contain encrypted secrets for the cluster"
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
    
    # Check if initialization playbook exists
    if [ ! -f "$PROJECT_DIR/$ANSIBLE_DIR/initialize_cluster.yaml" ]; then
        echo "ERROR: Initialization playbook not found: $PROJECT_DIR/$ANSIBLE_DIR/initialize_cluster.yaml"
        echo ""
        echo "Please ensure the initialization playbook exists"
        exit 1
    fi
    
    echo "Prerequisites validation passed"
}

# Display configuration information
show_configuration() {
    echo "=========================================="
    echo "OpenShift Cluster Initialization"
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
    
    echo "Starting cluster initialization..."
    echo "This will generate install-config.yaml and prepare the cluster for installation."
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
        -e @/runner/project/secrets/${CLUSTER}/secrets.yaml \
        --vault-password-file=/runner/all-clusters-resources/vault-password.txt \
        /runner/project/initialize_cluster.yaml -vvv
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "=========================================="
        echo "Cluster initialization completed successfully!"
        echo "=========================================="
        echo ""
        echo "Generated files:"
        echo "  - ansible/install-dir/install-config.yaml"
        echo "  - ansible/install-dir/install-config.yaml.orig (backup)"
        echo ""
        echo "Next steps:"
        echo "  This script completes the cluster initialization process."
        echo "  No additional scripts are required to run after this one."
        echo ""
        echo "To verify the configuration:"
        echo "  - Review: ansible/install-dir/install-config.yaml"
        echo "  - Test: cd 00-ocp-test && ./00-test-manifest.sh --dry-run"
        echo ""
    else
        echo ""
        echo "=========================================="
        echo "Cluster initialization failed!"
        echo "=========================================="
        echo ""
        echo "Please check the error messages above and resolve any issues."
        echo "Common issues:"
        echo "  - Missing or incorrect variable files"
        echo "  - Vault password or secrets issues"
        echo "  - Template processing errors"
        echo "  - Network connectivity problems"
        echo "  - Insufficient permissions"
        echo ""
        echo "Troubleshooting steps:"
        echo "  1. Verify cluster preparation was completed: ./010-run-prep-cluster-install.sh $CLUSTER $ENV"
        echo "  2. Check all variable files exist and are properly formatted"
        echo "  3. Validate vault password file accessibility"
        echo "  4. Review cluster and environment configurations"
        echo ""
        exit 1
    fi
}

# Protect against sourcing – must be run, not sourced.
if [ "${BASH_SOURCE[0]}" != "$0" ]; then
    echo "ERROR: This script must be executed, not sourced."
    echo "Run it like: ./020-run-initialize-cluster.sh lab lab"
    return 1 2>/dev/null || exit 1
fi

# Run main function
main


