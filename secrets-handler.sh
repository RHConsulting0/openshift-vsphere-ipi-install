#!/bin/bash

## FIXME: Add more detailed usage information and examples

# secrets-handler.sh - Ansible Vault Secret Management Handler
# Processes sensitive files using ansible-vault in a podman container

# Usage function
usage() {
    cat << EOF
Usage: $0 <action> <target_file> <vault_password_file> [output_file]

DESCRIPTION:
    Ansible Vault secret management handler for processing sensitive files using
    ansible-vault commands within a containerized execution environment.
    This script provides secure handling of encrypted secrets, certificates,
    SSH keys, and other sensitive data using container isolation.

ACTIONS:
    encrypt     Encrypt a plain text file using ansible-vault
    decrypt     Decrypt a vault file to plain text
    view        Display the decrypted contents of a vault file
    edit        Edit a vault file (opens in default editor)
    rekey       Change the vault password for a file
    create      Create a new encrypted vault file

PARAMETERS:
    action              The vault operation to perform (encrypt, decrypt, view, edit, rekey, create)
    target_file         Path to the file to operate on (relative to container paths)
    vault_password_file Path to the vault password file (relative to container paths)
    output_file         Optional output file for decrypt/create operations

EXAMPLES:
    # Encrypt a file
    $0 encrypt /runner/project/secrets/lab/secrets.yaml /runner/all-clusters-resources/vault-password.txt

    # Decrypt a file
    $0 decrypt /runner/project/secrets/lab/secrets.yaml /runner/all-clusters-resources/vault-password.txt /runner/project/decrypted-secrets.yaml

    # View encrypted file contents
    $0 view /runner/project/secrets/lab/secrets.yaml /runner/all-clusters-resources/vault-password.txt

    # Edit encrypted file
    $0 edit /runner/project/secrets/lab/secrets.yaml /runner/all-clusters-resources/vault-password.txt

    # Change vault password
    $0 rekey /runner/project/secrets/lab/secrets.yaml /runner/all-clusters-resources/vault-password.txt

    # Create new encrypted file
    $0 create /runner/project/secrets/lab/new-secrets.yaml /runner/all-clusters-resources/vault-password.txt

PREREQUISITES:
    - Podman must be installed and running
    - Execution environment image 'ocp-provision-ee:latest' must be built
    - Vault password file must exist and be accessible
    - Target file must exist (for encrypt, decrypt, view, edit, rekey operations)

CONTAINER INTEGRATION:
    - Uses execution environment container for consistent tooling
    - Automatically mounts project directories with proper SELinux context
    - Provides isolated environment for ansible-vault operations
    - Runs with root privileges for system-level operations

VOLUME MOUNTS:
    - /runner/project: Ansible project directory
    - /runner/all-clusters-resources: Cluster resources and vault password

SECURITY CONSIDERATIONS:
    - All operations use encrypted vault password file
    - Container provides isolated execution environment
    - Proper SELinux context for file access
    - No plain text secrets stored in memory
    - Secure file handling with proper permissions

COMMON FILE PATHS:
    # Secrets
    /runner/project/secrets/lab/secrets.yaml
    /runner/project/secrets/dev/secrets.yaml
    /runner/project/secrets/prod/secrets.yaml

    # Certificates
    /runner/all-clusters-resources/lab/cert.pem
    /runner/all-clusters-resources/lab/key.pem
    /runner/all-clusters-resources/lab/ca-bundle.crt

    # SSH Keys
    /runner/project/secrets/lab/id_rsa_odfl
    /runner/project/secrets/lab/id_ed25519_odfl

    # Passwords
    /runner/all-clusters-resources/lab/vsphere-password.txt
    /runner/all-clusters-resources/vault-password.txt

OPTIONS:
    -h, --help    Show this help message

WORKFLOW:
    1. Validates parameters and prerequisites
    2. Executes ansible-vault command in container environment
    3. Handles file operations with proper permissions
    4. Returns operation status and results

TROUBLESHOOTING:
    - Ensure execution environment image is built
    - Check file permissions and SELinux context
    - Verify vault password file accessibility
    - Review container logs for detailed error information

EOF
}

# Check for help option
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    usage
    exit 0
fi

# Validate parameters
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
    echo "ERROR: Missing required parameters"
    echo ""
    usage
    exit 1
fi

# Project and Ansible directories   
PROJECT_DIR="$(pwd)"
ANSIBLE_DIR="ansible"

# Container execution environment
EXECUTION_CONTAINER="ocp-provision-ee:latest"

ACTION=$1
TARGET_FILE=$2
VAULT_PWD_FILE=$3
OUTPUT_FILE=$4 

# Validate action
case "$ACTION" in
    encrypt|decrypt|view|edit|rekey|create)
        ;;
    *)
        echo "ERROR: Invalid action '$ACTION'"
        echo ""
        echo "Valid actions: encrypt, decrypt, view, edit, rekey, create"
        echo ""
        usage
        exit 1
        ;;
esac


# Validate prerequisites
validate_prerequisites() {
    # Check if podman is available
    if ! command -v podman &> /dev/null; then
        echo "ERROR: podman is not installed or not in PATH"
        echo "Please install podman and ensure it's available in your PATH"
        exit 1
    fi
    
    # Check if execution environment image exists
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
        echo "Please ensure the all-clusters-resources directory exists"
        exit 1
    fi
}

# Display configuration information
show_configuration() {
    echo "=========================================="
    echo "Ansible Vault Secret Management"
    echo "=========================================="
    echo "Action: $ACTION"
    echo "Target File: $TARGET_FILE"
    echo "Vault Password File: $VAULT_PWD_FILE"
    echo "Output File: ${OUTPUT_FILE:-'N/A'}"
    echo "Execution Container: $EXECUTION_CONTAINER"
    echo "Project Directory: $PROJECT_DIR"
    echo "Ansible Directory: $ANSIBLE_DIR"
    echo "=========================================="
    echo ""
}

# Function to run ansible-vault commands in a podman container
vault_podman() {
    local action="$1"       # encrypt, decrypt, view, edit, rekey, or create
    local file="$2"         # path to file
    local passfile="$3"     # vault password file path
    local output="$4"       # optional output file

    echo "Executing ansible-vault $action on $file"
    echo "Using vault password file: $passfile"
    if [ -n "$output" ]; then
        echo "Output file: $output"
    fi
    echo ""

    # Build the ansible-vault command
    local vault_cmd="ansible-vault $action $file --vault-password-file=$passfile"
    if [ -n "$output" ]; then
        vault_cmd="$vault_cmd --output $output"
    fi

    # Execute the command in the container
    if podman run --rm \
      --ipc=host \
      --user=root \
      --group-add=root \
      -v "${PROJECT_DIR}/${ANSIBLE_DIR}:/runner/project:Z" \
      -v "${PROJECT_DIR}/all-clusters-resources:/runner/all-clusters-resources:Z" \
      "$EXECUTION_CONTAINER" \
      sh -c "$vault_cmd"; then
        echo ""
        echo "SUCCESS: ansible-vault $action completed successfully"
        return 0
    else
        echo ""
        echo "ERROR: ansible-vault $action failed"
        echo ""
        echo "Common issues:"
        echo "  - Invalid vault password"
        echo "  - File not found or inaccessible"
        echo "  - Insufficient permissions"
        echo "  - Corrupted vault file"
        echo "  - Network connectivity issues"
        echo ""
        echo "Troubleshooting steps:"
        echo "  1. Verify vault password file exists and is accessible"
        echo "  2. Check file permissions and SELinux context"
        echo "  3. Ensure execution environment image is built"
        echo "  4. Review container logs for detailed error information"
        echo ""
        return 1
    fi
}

# Main execution function
main() {
    # Validate prerequisites
    validate_prerequisites
    
    # Show configuration
    show_configuration
    
    # Execute vault operation
    vault_podman "$ACTION" "$TARGET_FILE" "$VAULT_PWD_FILE" "$OUTPUT_FILE"
}

# Run main function if script is executed directly
if [ "${BASH_SOURCE[0]}" == "$0" ]; then
    main
fi

