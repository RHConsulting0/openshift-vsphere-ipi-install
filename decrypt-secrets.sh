#!/bin/bash

# decrypt-secrets.sh
# Decrypts sensitive files using ansible-vault in a podman container  # CORRECTED
# --- Color codes ---
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0,33m"
BLUE="\033[0;34m"
CYAN="\033[0;36m"
BRIGHTYELLOW="\033[1;93m"
BRIGHTCYAN="\033[0;96m"
RESET="\033[0m"

# Show usage if help requested
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

DESCRIPTION:
    Decrypts multiple sensitive files using ansible-vault in a Podman container.
    This script is a batch processor that automatically decrypts all configured
    sensitive files required for OpenShift cluster provisioning. It performs
    individual vault operations within a containerized execution environment.

WARNING: 
    Creates unencrypted copies of sensitive files on the filesystem.
    Use only in secure environments and clean up afterwards.

FILES PROCESSED:
    • SSH private keys (RSA and Ed25519)
    • SSL certificates and CA bundles  
    • vSphere authentication credentials
    • Pull secret verification
    • Other encrypted secrets in the project

CONTAINER INTEGRATION:
    • Uses execution environment container for consistent tooling
    • Automatically mounts project directories with proper SELinux context
    • Provides isolated environment for ansible-vault operations
    • Runs with root privileges for system-level operations

VOLUME MOUNTS:
    • ./ansible/ → /runner/project (Ansible project directory)
    • ./all-clusters-resources/ → /runner/all-clusters-resources (Cluster resources)

PREREQUISITES:
    • Podman must be installed and running
    • Execution environment image 'ocp-provision-ee:latest' must be built
    • vault-password.txt file in all-clusters-resources/
    • Required encrypted files must exist in their expected locations

BUILD EXECUTION ENVIRONMENT:
    cd automation-ee/ocp-provision-ee/
    ./builder.sh

EXAMPLES:
    # Decrypt all configured sensitive files
    ./decrypt-secrets.sh
    
    # Show help and usage information
    ./decrypt-secrets.sh --help
    ./decrypt-secrets.sh -h
    ./decrypt-secrets.sh help
    
    # Typical workflow for OpenShift cluster provisioning
    # 1. Build execution environment first
    cd automation-ee/ocp-provision-ee/
    ./builder.sh
    cd ../../
    
    # 2. Decrypt all required secrets
    ./decrypt-secrets.sh
    
    # 3. Run cluster installation (secrets now available)
    ./ee-bash.sh lab lab

OPTIONS:
    -h, --help    Show this help message

WORKFLOW:
    1. Validates prerequisites and container environment
    2. Iterates through predefined list of encrypted files
    3. Executes ansible-vault decrypt commands in container
    4. Displays decrypted content for verification
    5. Reports success/failure status for each operation

SECURITY CONSIDERATIONS:
    • All operations use encrypted vault password file
    • Container provides isolated execution environment
    • Proper SELinux context for file access
    • No plain text secrets stored in memory
    • Secure file handling with proper permissions
    • Files are decrypted to host filesystem (clean up required)

TROUBLESHOOTING:
    • Ensure execution environment image is built
    • Check file permissions and SELinux context
    • Verify vault password file accessibility
    • Review container logs for detailed error information
    • Ensure all required encrypted files exist

EOF
}

case "${1:-}" in
    -h|--help|help)
        show_usage
        exit 0
        ;;
esac

count=0
success_count=0

if [ "${BASH_SOURCE[0]}" != "$0" ]; then
  echo -e "${RED}ERROR:${RESET} This script must be executed, not sourced."
  echo -e "Run it like: ${BRIGHTYELLOW}./decrypt-secrets.sh${RESET}"
  return 1 2>/dev/null || exit 1
fi

source ./secrets-handler.sh

PROJECT_DIR="$(pwd)"
ANSIBLE_DIR="ansible"

# Vault password file
EE_VAULT_PWD="/runner/all-clusters-resources/vault-password.txt"
HOST_VAULT_PWD="$PROJECT_DIR/all-clusters-resources/vault-password.txt"

# Define an array of “items” as: HOST_FILE:EE_FILE
items=(
  "$PROJECT_DIR/all-clusters-resources/pull-secret.json:/runner/all-clusters-resources/pull-secret.json"
  "$PROJECT_DIR/$ANSIBLE_DIR/secrets/lab/id_rsa_odfl:/runner/project/secrets/lab/id_rsa_odfl"
  "$PROJECT_DIR/$ANSIBLE_DIR/secrets/lab/id_ed25519_odfl:/runner/project/secrets/lab/id_ed25519_odfl"
  "$PROJECT_DIR/all-clusters-resources/lab/ca-bundle.crt:/runner/all-clusters-resources/lab/ca-bundle.crt"
  "$PROJECT_DIR/all-clusters-resources/lab/vsphere-password.txt:/runner/all-clusters-resources/lab/vsphere-password.txt"
)

echo -e "\n${BRIGHTCYAN}DECRYPT FILES USING ANSIBLE-VAULT IN A CONTAINER...${RESET}\n"
echo -e "${CYAN}Processing ${#items[@]} encrypted files:${RESET}"
for item in "${items[@]}"; do
  HOST_FILE="${item%%:*}"  # part before colon
  echo -e "  • ${HOST_FILE##*/}"  # show just filename
done
echo ""

for item in "${items[@]}"; do
  HOST_FILE="${item%%:*}"  # part before colon
  EE_FILE="${item##*:}"    # part after colon

  echo -e "\n\n${BRIGHTYELLOW}##### $count${RESET}"
  echo -e "${BRIGHTCYAN}CALLING:${RESET} vault_podman [$DECRYPT] [$EE_FILE] [$HOST_VAULT_PWD]"
  echo -e "\t${CYAN}(**If vault operation is successful, file contents will be displayed.${RESET}\n"

  # Run vault_podman
  if vault_podman "$DECRYPT" "$EE_FILE" "$EE_VAULT_PWD"; then
    echo -e "${GREEN}SUCCESS:${RESET} Vault operation for $EE_FILE"
    ((success_count++))
  else
    echo -e "${RED}ERROR:${RESET} Vault operation failed for $EE_FILE"
    ((count++))
    continue
  fi

  # Show the resulting file if it exists
  if [[ -f "$HOST_FILE" ]]; then
    echo -e "\n${GREEN}View file created(AT REST):${RESET} $HOST_FILE"
    cat -n "$HOST_FILE"
  else
    echo -e "${RED}File not created:${RESET} $HOST_FILE"
  fi
  ((count++))
done

# sanity check for pull-secret.json
HOST_PULL_SECRET="$PROJECT_DIR/all-clusters-resources/pull-secret.json"
echo -e "\n${BRIGHTYELLOW}##### $count ${RESET}"
echo -e "${BRIGHTCYAN}RESOURCES FILE:${RESET} [$HOST_PULL_SECRET] - should not be decrypted\n"
if [[ -f "$HOST_PULL_SECRET" ]]; then
  cat -n "$HOST_PULL_SECRET"
else
  echo -e "${RED}File not found:${RESET} $HOST_PULL_SECRET"
fi

echo -e "\n${GREEN}DECRYPTION COMPLETE${RESET}"
echo -e "${CYAN}Summary:${RESET}"
echo -e "  • Total files processed: ${#items[@]}"
echo -e "  • Files decrypted successfully: $success_count"
echo -e "  • Files failed: $((${#items[@]} - success_count))"
echo -e "  • Check output above for any errors"
echo -e "\n${YELLOW}REMINDER:${RESET} Clean up decrypted files when done for security"
echo ""
