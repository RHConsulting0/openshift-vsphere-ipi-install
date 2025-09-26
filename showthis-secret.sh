#!/bin/bash

# dothis-secret.sh
# --- Color codes ---
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0,33m"
BLUE="\033[0;34m"
CYAN="\033[0;36m"
BRIGHTYELLOW="\033[1;93m"
BRIGHTCYAN="\033[0;96m"
RESET="\033[0m"

OPERATION=$1
SECRET_FILE=$2
OUT_SECRET_FILE=$3

# Vault password file
EE_VAULT_PWD="/runner/all-clusters-resources/vault-password.txt"
HOST_VAULT_PWD="$PROJECT_DIR/all-clusters-resources/vault-password.txt"

count=0

if [ "${BASH_SOURCE[0]}" != "$0" ]; then
  echo -e "${RED}ERROR:${RESET} This script must be executed, not sourced."
  echo -e "Run it like: ${BRIGHTYELLOW}./dothis-secrets.sh${RESET}"
  return 1 2>/dev/null || exit 1
fi  

source ./secrets-handler.sh

echo -e "\n${BRIGHTCYAN}${OPERATION} FILE USING ANSIBLE-VAULT IN A CONTAINER...${RESET}\n"

echo -e "\n\n${BRIGHTYELLOW}##### $count${RESET}"
echo -e "${BRIGHTCYAN}CALLING:${RESET} vault_podman [$OPERATION] [$SECRET_FILE] [$HOST_VAULT_PWD]"
echo -e "\t${CYAN}(**If vault operation is successful, file contents will be displayed.${RESET}\n"

# Run vault_podman
if vault_podman "$OPERATION" "$SECRET_FILE" "$EE_VAULT_PWD" "$OUT_SECRET_FILE"; then
  echo -e "${GREEN}SUCCESS:${RESET} Vault operation for $SECRET_FILE"
else
  echo -e "${RED}ERROR:${RESET} Vault operation failed for $SECRET_FILE"
  ((count++))
fi


echo -e "\n${GREEN}COMPLETE${RESET}\n"
