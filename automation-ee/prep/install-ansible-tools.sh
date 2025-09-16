#!/usr/bin/env bash
#
# Install ansible-builder and ansible-navigator on RHEL9 (no Git, no Podman)
# Usage: sudo ./install_ansible_tools.sh

set -euo pipefail

printf "\n=== Installing prerequisites (Python3 + pip) ===\n"
sudo dnf install -y python3 python3-pip

printf "\n=== Upgrading pip/setuptools/wheel ===\n"
python3 -m pip install --upgrade pip setuptools wheel

printf "\n=== Installing ansible-navigator and ansible-builder (latest stable) ===\n"
# Install under system Python – use --user if you prefer local installs
sudo python3 -m pip install --upgrade \
  "ansible-navigator" \
  "ansible-builder"

printf "\n=== Checking versions ===\n"
printf "Python: "; python3 --version
printf "ansible-navigator: "; ansible-navigator --version || true
printf "ansible-builder: "; ansible-builder --version || true

printf "\n=== Done! ===\n"
printf "You can now run 'ansible-navigator --version' and 'ansible-builder --version'.\n"
