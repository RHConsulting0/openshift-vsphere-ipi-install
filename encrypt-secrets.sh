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
    echo "Usage: $0"
    echo ""
    echo "Encrypts sensitive files using ansible-vault in a Podman container"
    echo ""
    echo "WARNING: This will OVERWRITE plaintext files with encrypted versions"
    echo "Make sure to backup plaintext files if needed before running"
    echo ""
    echo "Files encrypted:"
    echo "  • SSH private keys (RSA and Ed25519)"
    echo "  • SSL certificates and CA bundles"
    echo "  • vSphere authentication credentials"
    echo "  • Pull secret remains unencrypted (verification only)"
    echo ""
    echo "Prerequisites:"
    echo "  • secrets-handler.sh in same directory"
    echo "  • vault-password.txt file"
    echo "  • Podman container runtime"
    echo "  • Plaintext source files in expected locations"
    echo ""
    echo "After encryption, files are safe for version control storage"
    echo "Use decrypt-secrets.sh or view-secrets.sh to access content"
    echo ""
    echo "Use -h, --help, or help for detailed information"
}

case "${1:-}" in
    -h|--help|help)
        show_usage
        exit 0
        ;;
esac

count=0

if [ "${BASH_SOURCE[0]}" != "$0" ]; then
  echo -e "${RED}ERROR:${RESET} This script must be executed, not sourced."
  echo -e "Run it like: ${BRIGHTYELLOW}./encrypt-secrets.sh${RESET}"
  return 1 2>/dev/null || exit 1
fi  

count=0

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

for item in "${items[@]}"; do
  HOST_FILE="${item%%:*}"  # part before colon
  EE_FILE="${item##*:}"    # part after colon

  echo -e "\n\n${BRIGHTYELLOW}##### $count${RESET}"
  echo -e "${BRIGHTCYAN}CALLING:${RESET} vault_podman [$ENCRYPT] [$EE_FILE] [$HOST_VAULT_PWD]"
  echo -e "\t${CYAN}(**If vault operation is successful, file contents will be displayed.${RESET}\n"

  # Run vault_podman
  if vault_podman "$ENCRYPT" "$EE_FILE" "$EE_VAULT_PWD"; then
    echo -e "${GREEN}SUCCESS:${RESET} Vault operation for $EE_FILE"
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

echo -e "\n${GREEN}COMPLETE${RESET}\n"
