#!/bin/bash
#!/bin/bash

# view-secrets.sh - Usage Statement
show_usage() {
    cat << 'EOF'
NAME
    view-secrets.sh - View sensitive files using ansible-vault in a Podman container

SYNOPSIS
    ./view-secrets.sh

DESCRIPTION
    This script views encrypted sensitive files using ansible-vault within a Podman 
    container environment. It processes a predefined list of sensitive files and 
    displays their contents with color-coded feedback for easy identification of 
    success or failure states.

    The script automatically handles:
    • Ansible-vault encrypted files using vault password
    • SSH private keys (RSA and Ed25519)
    • Pull secrets for container registries
    • SSL certificates and CA bundles
    • vSphere authentication credentials

PREREQUISITES
    • Podman must be installed and accessible
    • secrets-handler.sh must be present in the same directory
    • Execution environment container image with ansible-vault
    • Vault password file at: all-clusters-resources/vault-password.txt
    • Script must be executed (not sourced)

FILES PROCESSED
    The script processes the following files:
    
    1. Pull Secret (Container Registry Authentication)
       • Host: ./all-clusters-resources/pull-secret.json
       • Container: /runner/all-clusters-resources/pull-secret.json
    
    2. SSH Private Key (RSA)
       • Host: ./ansible/secrets/lab/id_rsa_odfl
       • Container: /runner/project/secrets/lab/id_rsa_odfl
    
    3. SSH Private Key (Ed25519)
       • Host: ./ansible/secrets/lab/id_ed25519_odfl
       • Container: /runner/project/secrets/lab/id_ed25519_odfl
    
    4. CA Certificate Bundle
       • Host: ./all-clusters-resources/lab/ca-bundle.crt
       • Container: /runner/all-clusters-resources/lab/ca-bundle.crt
    
    5. vSphere Password
       • Host: ./all-clusters-resources/lab/vsphere-password.txt
       • Container: /runner/all-clusters-resources/lab/vsphere-password.txt

DIRECTORY STRUCTURE
    Expected project structure:
    
    project-root/
    ├── view-secrets.sh              # This script
    ├── secrets-handler.sh           # Required dependency
    ├── all-clusters-resources/
    │   ├── vault-password.txt       # Ansible vault password
    │   ├── pull-secret.json         # Container registry credentials
    │   └── lab/
    │       ├── ca-bundle.crt        # SSL certificates
    │       └── vsphere-password.txt # vSphere credentials
    └── ansible/
        └── secrets/
            └── lab/
                ├── id_rsa_odfl      # SSH private key (RSA)
                └── id_ed25519_odfl  # SSH private key (Ed25519)

ENVIRONMENT VARIABLES
    PROJECT_DIR     Current working directory (automatically set)
    ANSIBLE_DIR     Ansible subdirectory name (default: "ansible")

CONTAINER PATHS
    EE_VAULT_PWD    /runner/all-clusters-resources/vault-password.txt
    HOST_VAULT_PWD  $PROJECT_DIR/all-clusters-resources/vault-password.txt

OUTPUT
    • Color-coded status messages:
      - CYAN: Information and operation calls
      - GREEN: Success messages and file contents
      - RED: Error messages and failures
      - YELLOW: File paths and identifiers
    
    • File contents are displayed with line numbers using 'cat -n'
    • Each processed file is numbered sequentially
    • Final sanity check displays pull-secret.json content

EXIT CODES
    0    Success - all operations completed
    1    Error - script was sourced instead of executed
    
    Note: Individual file processing errors are reported but don't stop execution

EXAMPLES
    Basic usage:
        $ ./view-secrets.sh
    
    Check if script is executable:
        $ chmod +x view-secrets.sh
        $ ./view-secrets.sh
    
    Verify prerequisites:
        $ ls -la secrets-handler.sh
        $ ls -la all-clusters-resources/vault-password.txt

SECURITY CONSIDERATIONS
    • Sensitive file contents are displayed in terminal output
    • Ensure terminal history is cleared after use
    • Run only in secure environments
    • Vault password file contains sensitive authentication data
    • SSH private keys and passwords are displayed in plaintext

DEPENDENCIES
    Required Files:
    • secrets-handler.sh (must be in same directory)
    • vault-password.txt (for ansible-vault decryption)
    
    Required Commands:
    • podman (container runtime)
    • ansible-vault (within container)
    • bash (shell environment)

TROUBLESHOOTING
    Common Issues:
    
    1. "This script must be executed, not sourced"
       Solution: Use ./view-secrets.sh instead of source view-secrets.sh
    
    2. "secrets-handler.sh: No such file or directory"
       Solution: Ensure secrets-handler.sh is in the same directory
    
    3. "Vault operation failed"
       Solution: Check vault password file and file encryption status
    
    4. "File not found" errors
       Solution: Verify directory structure matches expected layout
    
    5. Container/Podman errors
       Solution: Ensure Podman is installed and execution environment is available

AUTHOR
    Created for OpenShift cluster deployment automation
    
NOTES
    • This script is designed for lab/development environments
    • All file paths are relative to the current working directory
    • The script uses a predefined list of files (not configurable via CLI)
    • Container paths follow ansible-runner execution environment conventions

SEE ALSO
    secrets-handler.sh(1), ansible-vault(1), podman(1)

EOF
}

# Check if help was requested
case "${1:-}" in
    -h|--help|help)
        show_usage
        exit 0
        ;;
esac

# --- Color codes ---
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0,33m"
BLUE="\033[0;34m"
CYAN="\033[0;36m"
BRIGHTYELLOW="\033[1;93m"
BRIGHTCYAN="\033[0;96m"
RESET="\033[0m"

count=0

if [ "${BASH_SOURCE[0]}" != "$0" ]; then
  echo -e "${RED}ERROR:${RESET} This script must be executed, not sourced."
  echo -e "Run it like: ${BRIGHTYELLOW}./view-secrets.sh${RESET}"
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

echo -e "\n${BRIGHTCYAN}VIEW FILES USING ANSIBLE-VAULT IN A CONTAINER...${RESET}\n"


for item in "${items[@]}"; do
  HOST_FILE="${item%%:*}"  # part before colon
  EE_FILE="${item##*:}"    # part after colon

  echo -e "\n\n${BRIGHTYELLOW}##### $count${RESET}"
  echo -e "${BRIGHTCYAN}CALLING:${RESET} vault_podman [$VIEW] [$EE_FILE] [$HOST_VAULT_PWD]"
  echo -e "\t${CYAN}(**If vault operation is successful, file contents will be displayed.${RESET}\n"

  # Run vault_podman
  if vault_podman "$VIEW" "$EE_FILE" "$EE_VAULT_PWD"; then
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
