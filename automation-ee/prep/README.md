# Prerequisites and Setup

This directory contains scripts and documentation for setting up the prerequisites required to build and use the OpenShift vSphere IPI automation execution environment.

> **Quick Start**: Run `./install_ansible_tools.sh` to automatically install all prerequisites, or follow the manual installation steps below.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Installation Script](#installation-script)
- [Manual Installation](#manual-installation)
- [Verification](#verification)
- [Troubleshooting](#troubleshooting)

## Overview

Before building and using the execution environment, you need to install the necessary tools and dependencies on your host system. This directory provides an automated installation script and manual instructions for setting up:

- **Podman**: Container runtime for running the execution environment
- **Python 3**: Python runtime for Ansible tools
- **ansible-builder**: Tool for building execution environments (≥3.0.0)
- **ansible-navigator**: Tool for running Ansible playbooks in execution environments (≥2.16.0)
- **Git**: Version control system

### Installation Methods

1. **Automated Installation** (Recommended): Use the provided script for quick setup
2. **Manual Installation**: Step-by-step installation for custom environments
3. **Docker Alternative**: Instructions for using Docker instead of Podman

## Prerequisites

### System Requirements
- **Operating System**: Linux (RHEL 9+, Fedora, Ubuntu 20.04+, or compatible)
- **Architecture**: x86_64 (amd64)
- **Memory**: Minimum 8GB RAM (16GB recommended for large builds)
- **Storage**: 20GB+ free disk space (50GB+ recommended for full development)
- **Network**: Internet access for downloading packages and images
- **CPU**: 2+ cores recommended for faster builds

### Required Permissions
- **sudo access**: Required for installing system packages
- **User permissions**: Ability to install Python packages in user directory
- **Container permissions**: User must be able to run containers (added to docker/podman group)

### Supported Distributions
- **Red Hat Enterprise Linux**: 9.0+
- **CentOS Stream**: 9+
- **Fedora**: 37+
- **Ubuntu**: 20.04 LTS, 22.04 LTS, 24.04 LTS
- **Debian**: 11+, 12+
- **SUSE Linux Enterprise Server**: 15 SP3+

## Installation Script

### `install_ansible_tools.sh`

This automated script installs all required prerequisites:

```bash
#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# install_ansible_tools.sh
# Installs ansible-builder and ansible-navigator plus prerequisites on RHEL/Fedora.
# ---------------------------------------------------------------------------

set -euo pipefail

echo "==> Installing prerequisites..."
# Use dnf if available, otherwise yum
if command -v dnf >/dev/null 2>&1; then
    PKG_MGR="dnf"
else
    PKG_MGR="yum"
fi

sudo ${PKG_MGR} -y install python3 python3-pip podman git

echo "==> Upgrading pip..."
python3 -m pip install --upgrade pip wheel setuptools

echo "==> Installing ansible-builder and ansible-navigator via pip..."
python3 -m pip install --user "ansible-builder>=3.0.0" "ansible-navigator>=2.16.0"

# Add ~/.local/bin to PATH if not already
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo "export PATH=\$HOME/.local/bin:\$PATH" >> "$HOME/.bashrc"
    export PATH="$HOME/.local/bin:$PATH"
    echo "==> Added ~/.local/bin to PATH"
fi

echo "==> Checking versions..."
printf "\nansible-builder version:\n"
ansible-builder --version || echo "ansible-builder not found in PATH."

printf "\nansible-navigator version:\n"
ansible-navigator --version || echo "ansible-navigator not found in PATH."

printf "\npodman version:\n"
podman --version || echo "podman not installed or not in PATH."

echo -e "\n==> Installation complete. Log out/in or run 'source ~/.bashrc' to refresh your PATH if needed."
```

### How to Use

1. **Make the script executable**:
```bash
chmod +x install_ansible_tools.sh
```

2. **Run the installation script**:
```bash
./install_ansible_tools.sh
```

3. **Refresh your shell environment**:
```bash
source ~/.bashrc
# or logout and login again
```

### What the Script Does

- **System Packages**: Installs Python 3, pip, Podman, and Git using the system package manager
- **Python Environment**: Upgrades pip, wheel, and setuptools to latest versions
- **Ansible Tools**: Installs ansible-builder ≥3.0.0 and ansible-navigator ≥2.16.0 to user directory
- **PATH Configuration**: Adds ~/.local/bin to PATH for accessing installed tools
- **Verification**: Checks that all tools are properly installed and accessible

## Manual Installation

If you prefer to install the prerequisites manually or the automated script doesn't work for your environment:

### 1. Install System Packages

#### On RHEL/CentOS/Fedora:
```bash
# Using dnf (preferred)
sudo dnf install -y python3 python3-pip podman git

# Or using yum (older systems)
sudo yum install -y python3 python3-pip podman git
```

#### On Ubuntu/Debian:
```bash
# Update package lists
sudo apt update

# Install required packages
sudo apt install -y python3 python3-pip podman git curl

# Add user to podman group (logout/login required)
sudo usermod -aG podman $USER
```

#### On SUSE Linux Enterprise Server:
```bash
# Install required packages
sudo zypper install -y python3 python3-pip podman git curl

# Add user to podman group
sudo usermod -aG podman $USER
```

### 2. Upgrade Python Package Manager
```bash
python3 -m pip install --upgrade pip wheel setuptools
```

### 3. Install Ansible Tools
```bash
# Install to user directory
python3 -m pip install --user "ansible-builder>=3.0.0" "ansible-navigator>=2.16.0"
```

### 4. Configure PATH
Add the following to your `~/.bashrc` or `~/.profile`:
```bash
export PATH="$HOME/.local/bin:$PATH"
```

Then reload your shell:
```bash
source ~/.bashrc
# or logout and login again
```

### 5. Configure Container Runtime (if needed)
```bash
# For Podman rootless mode
podman system migrate

# For Docker (alternative to Podman)
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
```

## Verification

After installation, verify that all tools are working correctly:

### Check Tool Versions
```bash
# Check ansible-builder
ansible-builder --version

# Check ansible-navigator
ansible-navigator --version

# Check podman
podman --version

# Check Python
python3 --version
```

### Expected Output
```
ansible-builder 3.0.0
ansible-navigator 2.16.0
podman version 4.0.0
Python 3.11.0
```

### Additional Verification
```bash
# Check Python packages
python3 -m pip list | grep -E "(ansible|builder|navigator)"

# Check container runtime
podman info

# Check Git configuration
git --version
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### Test Podman Functionality
```bash
# Test podman can run containers
podman run --rm hello-world

# Test podman can pull images
podman pull registry.redhat.io/ansible-automation-platform-25/ee-supported-rhel9:latest
```

### Test Ansible Tools
```bash
# Test ansible-builder can create a basic EE
mkdir test-ee
cd test-ee
cat > execution-environment.yml << EOF
version: 1
dependencies:
  galaxy:
    collections:
      - name: ansible.posix
EOF
ansible-builder build --tag test-ee:latest
cd ..
rm -rf test-ee

# Test ansible-navigator
ansible-navigator --version
ansible-navigator config --help
```

## Troubleshooting

### Common Issues

#### Permission Denied
```bash
# If you get permission denied errors
chmod +x install_ansible_tools.sh
```

#### Package Manager Not Found
```bash
# Check available package managers
which dnf yum apt

# Install missing package manager
# On RHEL/CentOS 8+:
sudo yum install -y dnf

# On older systems:
sudo yum install -y yum-utils
```

#### Python Package Installation Fails
```bash
# Upgrade pip first
python3 -m pip install --upgrade pip

# Install with user flag
python3 -m pip install --user --upgrade ansible-builder ansible-navigator

# Check Python path
python3 -c "import sys; print(sys.path)"
```

#### PATH Issues
```bash
# Check if ~/.local/bin is in PATH
echo $PATH | grep -o "$HOME/.local/bin"

# Add to PATH manually
export PATH="$HOME/.local/bin:$PATH"

# Make permanent
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
```

#### Podman Issues
```bash
# Check if podman is running
podman info

# Start podman service if needed
sudo systemctl start podman

# Check podman configuration
podman system info

# Enable podman socket for rootless mode
systemctl --user enable --now podman.socket

# Check user groups
groups $USER

# Add user to podman group if needed
sudo usermod -aG podman $USER
# Note: Logout and login required after adding to group
```

#### Network Issues
```bash
# Test internet connectivity
curl -I https://pypi.org

# Test registry access
podman pull hello-world

# Check DNS resolution
nslookup pypi.org
```

### Debug Commands

#### Check Installation
```bash
# Check installed packages
python3 -m pip list | grep -E "(ansible|builder|navigator)"

# Check tool locations
which ansible-builder ansible-navigator podman

# Check Python modules
python3 -c "import ansible_builder; print(ansible_builder.__version__)"
python3 -c "import ansible_navigator; print(ansible_navigator.__version__)"
```

#### Check System Information
```bash
# Check OS version
cat /etc/os-release

# Check available memory
free -h

# Check disk space
df -h

# Check network connectivity
ping -c 3 8.8.8.8
```

### Getting Help

#### Tool Help
```bash
# Get help for each tool
ansible-builder --help
ansible-navigator --help
podman --help
```

#### Log Files
```bash
# Check installation logs
journalctl -u podman

# Check Python pip logs
python3 -m pip install --user --verbose ansible-builder
```

#### Community Resources
- [Ansible Documentation](https://docs.ansible.com/)
- [Podman Documentation](https://docs.podman.io/)
- [Python pip Documentation](https://pip.pypa.io/)

---

## Next Steps

After successfully installing the prerequisites:

1. **Build the execution environment**:
   ```bash
   cd ../ocp-provision-ee/
   ./builder.sh
   ```

2. **Test the execution environment**:
   ```bash
   podman run --rm ocp-provision-ee:latest openshift-install version
   podman run --rm ocp-provision-ee:latest oc version --client
   podman run --rm ocp-provision-ee:latest helm version
   ```

3. **Start using the automation**:
   ```bash
   cd ../
   ./ee-bash.sh lab lab
   ```

4. **Verify complete setup**:
   ```bash
   # Check all tools are available
   ./ee-bash.sh lab lab
   # Inside container:
   openshift-install version
   oc version --client
   helm version
   kustomize version
   ansible --version
   ```

## Alternative Installation Methods

### Using Docker Instead of Podman
```bash
# Install Docker
sudo dnf install -y docker  # RHEL/Fedora
# or
sudo apt install -y docker.io  # Ubuntu/Debian

# Start Docker service
sudo systemctl enable --now docker

# Add user to docker group
sudo usermod -aG docker $USER

# Logout and login, then test
docker run --rm hello-world
```

### Using Python Virtual Environment
```bash
# Create virtual environment
python3 -m venv ~/ansible-venv

# Activate virtual environment
source ~/ansible-venv/bin/activate

# Install tools in virtual environment
pip install --upgrade pip
pip install "ansible-builder>=3.0.0" "ansible-navigator>=2.16.0"

# Add to PATH
echo 'export PATH="$HOME/ansible-venv/bin:$PATH"' >> ~/.bashrc
```

---

## Support and Resources

### Official Documentation
- [Ansible Builder Documentation](https://ansible.readthedocs.io/projects/builder/)
- [Ansible Navigator Documentation](https://ansible.readthedocs.io/projects/navigator/)
- [Podman Documentation](https://docs.podman.io/)
- [Python pip Documentation](https://pip.pypa.io/)

### Project Maintenance
- **Maintainer**: ODFL Platform Team
- **Last Updated**: December 2024
- **Version**: 1.0.0
- **License**: Internal Use Only
