#!/bin/bash

# showthis-secret.sh - Ansible Vault Secret Management Tool
# --- Color codes ---
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
CYAN="\033[0;36m"
BRIGHTYELLOW="\033[1;93m"
BRIGHTCYAN="\033[0;96m"
RESET="\033[0m"

# Usage function
usage() {
    cat << EOF
Usage: $0 <operation> <secret_file> [output_file]

DESCRIPTION:
    Manage Ansible Vault encrypted secrets using containerized ansible-vault.
    This script provides a secure way to view, edit, and manage encrypted secret files
    using the execution environment container.

OPERATIONS:
    view        Display the decrypted contents of a vault file
    edit        Edit a vault file (opens in default editor)
    encrypt     Encrypt a plain text file
    decrypt     Decrypt a vault file to plain text
    rekey       Change the vault password for a file
    create      Create a new encrypted vault file

PARAMETERS:
    operation   The vault operation to perform (view, edit, encrypt, decrypt, rekey, create)
    secret_file Path to the vault file to operate on
    output_file Optional output file for decrypt/create operations

EXAMPLES:
    $0 view ansible/secrets/lab/secrets.yaml
    $0 edit ansible/secrets/lab/secrets.yaml
    $0 encrypt plain-secrets.yaml ansible/secrets/lab/secrets.yaml
    $0 decrypt ansible/secrets/lab/secrets.yaml decrypted-secrets.yaml
    $0 rekey ansible/secrets/lab/secrets.yaml
    $0 create ansible/secrets/lab/new-secrets.yaml

PREREQUISITES:
    - Podman must be installed and running
    - Execution environment image 'ocp-provision-ee:latest' must be built
    - Vault password file must exist at all-clusters-resources/vault-password.txt
    - secrets-handler.sh script must be available in the same directory

CONTAINER INTEGRATION:
    - Uses execution environment container for ansible-vault operations
    - Automatically mounts project directories with proper SELinux context
    - Provides consistent vault password file location
    - Runs in isolated environment for security

SECURITY CONSIDERATIONS:
    - All operations use encrypted vault password file
    - Container provides isolated execution environment
    - Proper SELinux context for file access
    - No plain text secrets stored in memory

OPTIONS:
    -h, --help    Show this help message

WORKFLOW:
    1. Validates prerequisites and parameters
    2. Sources secrets-handler.sh for vault functions
    3. Executes vault operation in container environment
    4. Displays results with color-coded status messages

TROUBLESHOOTING:
    - Ensure vault password file exists and is accessible
    - Verify execution environment image is built
    - Check file permissions and SELinux context
    - Review container logs for detailed error information

EOF
}

# Check for help option
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    usage
    exit 0
fi

# Validate parameters
if [ -z "$1" ] || [ -z "$2" ]; then
    echo -e "${RED}ERROR:${RESET} Missing required parameters"
    echo ""
    usage
    exit 1
fi

OPERATION=$1
SECRET_FILE=$2
OUT_SECRET_FILE=$3

# Validate operation
case "$OPERATION" in
    view|edit|encrypt|decrypt|rekey|create)
        ;;
    *)
        echo -e "${RED}ERROR:${RESET} Invalid operation '$OPERATION'"
        echo ""
        echo "Valid operations: view, edit, encrypt, decrypt, rekey, create"
        echo ""
        usage
        exit 1
        ;;
esac

# Vault password file paths
EE_VAULT_PWD="/runner/all-clusters-resources/vault-password.txt"
HOST_VAULT_PWD="${PROJECT_DIR:-$(pwd)}/all-clusters-resources/vault-password.txt"

count=0

# Protect against sourcing
if [ "${BASH_SOURCE[0]}" != "$0" ]; then
    echo -e "${RED}ERROR:${RESET} This script must be executed, not sourced."
    echo -e "Run it like: ${BRIGHTYELLOW}./showthis-secret.sh${RESET}"
    return 1 2>/dev/null || exit 1
fi

# Validate prerequisites
validate_prerequisites() {
    # Check if secrets-handler.sh exists
    if [ ! -f "./secrets-handler.sh" ]; then
        echo -e "${RED}ERROR:${RESET} secrets-handler.sh not found in current directory"
        echo "Please ensure secrets-handler.sh is available in the same directory as this script."
        exit 1
    fi
    
    # Check if vault password file exists
    if [ ! -f "$HOST_VAULT_PWD" ]; then
        echo -e "${RED}ERROR:${RESET} Vault password file not found: $HOST_VAULT_PWD"
        echo ""
        echo "Please ensure the vault password file exists at:"
        echo "  all-clusters-resources/vault-password.txt"
        exit 1
    fi
    
    # Check if execution environment image exists
    if ! podman image exists "ocp-provision-ee:latest" 2>/dev/null; then
        echo -e "${RED}ERROR:${RESET} Execution environment image 'ocp-provision-ee:latest' not found"
        echo ""
        echo "To build the execution environment, run:"
        echo "  cd automation-ee/ocp-provision-ee/"
        echo "  ./builder.sh"
        echo ""
        exit 1
    fi
    
    # Check if secret file exists (for view, edit, decrypt, rekey operations)
    if [[ "$OPERATION" =~ ^(view|edit|decrypt|rekey)$ ]] && [ ! -f "$SECRET_FILE" ]; then
        echo -e "${RED}ERROR:${RESET} Secret file not found: $SECRET_FILE"
        echo ""
        echo "Please ensure the secret file exists and the path is correct."
        exit 1
    fi
}

# Display configuration information
show_configuration() {
    echo "=========================================="
    echo "Ansible Vault Secret Management"
    echo "=========================================="
    echo "Operation: $OPERATION"
    echo "Secret File: $SECRET_FILE"
    echo "Output File: ${OUT_SECRET_FILE:-'N/A'}"
    echo "Vault Password: $HOST_VAULT_PWD"
    echo "Execution Container: ocp-provision-ee:latest"
    echo "=========================================="
    echo ""
}

# Main execution
main() {
    # Validate prerequisites
    validate_prerequisites
    
    # Show configuration
    show_configuration
    
    # Source secrets handler
    source ./secrets-handler.sh
    
    echo -e "\n${BRIGHTCYAN}${OPERATION^^} FILE USING ANSIBLE-VAULT IN A CONTAINER...${RESET}\n"
    
    echo -e "\n\n${BRIGHTYELLOW}##### Operation $((count + 1))${RESET}"
    echo -e "${BRIGHTCYAN}CALLING:${RESET} vault_podman [$OPERATION] [$SECRET_FILE] [$HOST_VAULT_PWD]"
    echo -e "\t${CYAN}(**If vault operation is successful, file contents will be displayed.**)${RESET}\n"
    
    # Run vault_podman
    if vault_podman "$OPERATION" "$SECRET_FILE" "$EE_VAULT_PWD" "$OUT_SECRET_FILE"; then
        echo -e "${GREEN}SUCCESS:${RESET} Vault operation '$OPERATION' completed for $SECRET_FILE"
    else
        echo -e "${RED}ERROR:${RESET} Vault operation '$OPERATION' failed for $SECRET_FILE"
        ((count++))
        exit 1
    fi
    
    echo -e "\n${GREEN}OPERATION COMPLETE${RESET}\n"
}

# Run main function
main
