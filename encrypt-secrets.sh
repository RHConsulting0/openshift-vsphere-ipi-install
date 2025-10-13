#!/bin/bash

#!/bin/bash

# encrypt-secrets.sh
# Encrypts sensitive files using ansible-vault in a podman container

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
    Encrypts multiple sensitive files using ansible-vault in a Podman container.
    This script is a batch processor that automatically encrypts all configured
    sensitive files required for OpenShift cluster provisioning. It performs
    individual vault operations within a containerized execution environment.

WARNING: 
    This will OVERWRITE plaintext files with encrypted versions.
    Make sure to backup plaintext files if needed before running.

FILES ENCRYPTED:
    • SSH private keys (RSA and Ed25519)
    • SSL certificates and CA bundles
    • vSphere authentication credentials
    • Other sensitive configuration files
    • Pull secret remains unencrypted (verification only)

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
    • Plaintext source files must exist in their expected locations

BUILD EXECUTION ENVIRONMENT:
    cd automation-ee/ocp-provision-ee/
    ./builder.sh

EXAMPLES:
    # Encrypt all configured sensitive files
    ./encrypt-secrets.sh
    
    # Show help and usage information
    ./encrypt-secrets.sh --help
    ./encrypt-secrets.sh -h
    ./encrypt-secrets.sh help
    
    # Typical workflow for preparing secrets for version control
    # 1. Build execution environment first
    cd automation-ee/ocp-provision-ee/
    ./builder.sh
    cd ../../
    
    # 2. Ensure plaintext files exist in correct locations
    # 3. Encrypt all sensitive files
    ./encrypt-secrets.sh
    
    # 4. Files are now safe for version control storage

OPTIONS:
    -h, --help    Show this help message

WORKFLOW:
    1. Validates prerequisites and container environment
    2. Iterates through predefined list of plaintext files
    3. Executes ansible-vault encrypt commands in container
    4. Displays encrypted content for verification
    5. Reports success/failure status for each operation

SECURITY CONSIDERATIONS:
    • All operations use encrypted vault password file
    • Container provides isolated execution environment
    • Proper SELinux context for file access
    • No plain text secrets stored in memory
    • Secure file handling with proper permissions
    • Files are encrypted in place (backup recommended)

POST-ENCRYPTION:
    • Files are safe for version control storage
    • Use decrypt-secrets.sh to access content when needed
    • Keep vault password file secure and separate
    • Consider backing up encrypted files

TROUBLESHOOTING:
    • Ensure execution environment image is built
    • Check file permissions and SELinux context
    • Verify vault password file accessibility
    • Review container logs for detailed error information
    • Ensure all required plaintext files exist

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
  echo -e "Run it like: ${BRIGHTYELLOW}./encrypt-secrets.sh${RESET}"
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

echo -e "\n${BRIGHTCYAN}ENCRYPT FILES USING ANSIBLE-VAULT IN A CONTAINER...${RESET}\n"
echo -e "${CYAN}Processing ${#items[@]} plaintext files:${RESET}"
for item in "${items[@]}"; do
  HOST_FILE="${item%%:*}"  # part before colon
  echo -e "  • ${HOST_FILE##*/}"  # show just filename
done
echo ""

for item in "${items[@]}"; do
  HOST_FILE="${item%%:*}"  # part before colon
  EE_FILE="${item##*:}"    # part after colon

  echo -e "\n\n${BRIGHTYELLOW}##### $count${RESET}"
  echo -e "${BRIGHTCYAN}CALLING:${RESET} vault_podman [$ENCRYPT] [$EE_FILE] [$HOST_VAULT_PWD]"
  echo -e "\t${CYAN}(**If vault operation is successful, file contents will be displayed.${RESET}\n"

  # Run vault_podman
  if vault_podman "$ENCRYPT" "$EE_FILE" "$EE_VAULT_PWD"; then
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
echo -e "${BRIGHTCYAN}RESOURCES FILE:${RESET} [$HOST_PULL_SECRET] - should not be encrypted\n"
if [[ -f "$HOST_PULL_SECRET" ]]; then
  cat -n "$HOST_PULL_SECRET"
else
  echo -e "${RED}File not found:${RESET} $HOST_PULL_SECRET"
fi

echo -e "\n${GREEN}ENCRYPTION COMPLETE${RESET}"
echo -e "${CYAN}Summary:${RESET}"
echo -e "  • Total files processed: ${#items[@]}"
echo -e "  • Files encrypted successfully: $success_count"
echo -e "  • Files failed: $((${#items[@]} - success_count))"
echo -e "  • Check output above for any errors"
echo -e "\n${YELLOW}REMINDER:${RESET} Files are now encrypted and safe for version control"
echo ""
