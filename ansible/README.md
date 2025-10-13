# OpenShift vSphere IPI Ansible Automation

A comprehensive Ansible automation framework for OpenShift cluster installation, management, and day-2 operations on VMware vSphere using Installer-Provisioned Infrastructure (IPI).

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Directory Structure](#directory-structure)
- [Playbooks](#playbooks)
- [Configuration Management](#configuration-management)
- [Roles](#roles)
- [Templates](#templates)
- [Secrets Management](#secrets-management)
- [Usage Examples](#usage-examples)
- [Troubleshooting](#troubleshooting)
- [Integration](#integration)

## Overview

This Ansible automation framework provides a complete solution for OpenShift cluster lifecycle management on VMware vSphere. It includes installation, monitoring, validation, GitOps setup, and day-2 operations with comprehensive error handling and logging.

### Key Features

- **Complete Cluster Lifecycle**: Installation, monitoring, validation, and destruction
- **GitOps Integration**: ArgoCD and GitOps operator installation
- **Comprehensive Monitoring**: Real-time installation progress tracking
- **Secrets Management**: Encrypted secrets with Ansible Vault
- **Modular Design**: Reusable roles and templates
- **Production Ready**: Error handling, logging, and validation

## Quick Start

### Prerequisites

1. **Execution Environment**: Build the execution environment first
   ```bash
   cd automation-ee/ocp-provision-ee
   ./builder.sh
   ```

2. **Configuration**: Ensure cluster configuration is complete
   - Update `group_vars/cluster/<cluster>/all.yaml`
   - Configure secrets in `secrets/<cluster>/secrets.yaml`
   - Set environment variables in `group_vars/env/<env>/`

### Complete Installation

#### Option 1: Automated Scripts (Recommended)
```bash
# Step 1: Prepare cluster (includes initialization)
./010-run-prep-cluster-install.sh lab lab

# Step 2: Install and monitor cluster
./030-run-install-and-monitor.sh lab lab
```

#### Option 2: Manual Playbook Execution
```bash
# Step 1: Prepare cluster (includes initialization)
ansible-playbook -i inventory.yml \
  -e @group_vars/cluster/lab/all.yaml \
  -e @group_vars/env/lab/default-vault.yaml \
  -e @group_vars/env/lab/all.yaml \
  -e @secrets/lab/secrets.yaml \
  --vault-password-file=../all-clusters-resources/vault-password.txt \
  prep_cluster_install.yaml

# Step 2: Install and monitor cluster
ansible-playbook -i inventory.yml \
  -e @group_vars/cluster/lab/all.yaml \
  -e @group_vars/env/lab/default-vault.yaml \
  -e @group_vars/env/lab/all.yaml \
  -e @secrets/lab/secrets.yaml \
  --vault-password-file=../all-clusters-resources/vault-password.txt \
  install_and_monitor_cluster.yaml

# Step 3: Validate cluster (optional but recommended)
ansible-playbook -i inventory.yml \
  -e @group_vars/cluster/lab/all.yaml \
  -e @group_vars/env/lab/default-vault.yaml \
  -e @group_vars/env/lab/all.yaml \
  -e @secrets/lab/secrets.yaml \
  --vault-password-file=../all-clusters-resources/vault-password.txt \
  validate_cluster_and_kubeconfig.yaml
```

#### Option 3: Using Execution Environment
```bash
# Using ansible-navigator
ansible-navigator run prep_cluster_install.yaml \
  --eei ocp-provision-ee:latest \
  -m stdout

ansible-navigator run install_and_monitor_cluster.yaml \
  --eei ocp-provision-ee:latest \
  -m stdout

# Using podman directly
podman run --rm -it \
  -v $(pwd):/runner/project:Z \
  -e KUBECONFIG=/runner/project/install-dir/auth/kubeconfig \
  ocp-provision-ee:latest \
  ansible-playbook /runner/project/prep_cluster_install.yaml

podman run --rm -it \
  -v $(pwd):/runner/project:Z \
  -e KUBECONFIG=/runner/project/install-dir/auth/kubeconfig \
  ocp-provision-ee:latest \
  ansible-playbook /runner/project/install_and_monitor_cluster.yaml
```

## Directory Structure

```
ansible/
├── README.md                           # This file
├── ansible.cfg                         # Ansible configuration
├── inventory.yml                       # Main inventory file
├── group_vars/                         # Hierarchical variable management
│   ├── all.yaml                        # Global variables
│   ├── cluster/                        # Cluster-specific variables
│   │   ├── all.yaml                    # Default cluster variables
│   │   ├── lab/all.yaml                # Lab cluster configuration
│   │   └── hub-lab/                    # Hub lab cluster configuration
│   └── env/                            # Environment-specific variables
│       └── lab/                        # Lab environment configuration
│           ├── all.yaml                # Lab environment variables
│           └── default-vault.yaml      # Lab environment secrets
├── roles/                              # Ansible roles
│   ├── prep_cluster_install/           # Cluster preparation and initialization role
│   ├── install_and_monitor_cluster/    # Installation and monitoring role
│   ├── validate_cluster_and_kubeconfig/ # Cluster validation role
│   ├── install_gitops_operator/        # GitOps operator installation
│   ├── install_argocd/                 # ArgoCD installation
│   ├── init_gitops/                    # GitOps initialization
│   ├── destroy_cluster/                # Cluster destruction
│   └── store_cluster_inventory/        # Cluster inventory storage
├── templates/                          # Jinja2 templates
│   ├── install-config.yaml.j2         # OpenShift install configuration template
│   ├── gitops-operator-values.yaml    # GitOps operator values template
│   └── deploy-helper-script.sh        # Deployment helper script
├── secrets/                            # Encrypted secrets
│   └── lab/                            # Lab environment secrets
│       ├── secrets.yaml                # Encrypted secrets file
│       ├── id_ed25519_odfl             # SSH private key
│       ├── id_ed25519_odfl.pub         # SSH public key
│       ├── id_rsa_odfl                 # RSA private key
│       ├── id_rsa_odfl.pub             # RSA public key
│       ├── secrets (copy).yaml         # Backup secrets file
│       └── README.md                   # Secrets documentation
├── install-dir/                        # Installation artifacts
│   ├── auth/                           # Authentication files
│   ├── manifests/                      # OpenShift manifests
│   ├── cluster-api/                    # Cluster API files
│   └── openshift/                      # OpenShift specific files
├── install-dir-backup/                 # Installation backup
├── kubeconfig-backup/                  # Kubeconfig backups
├── ansible-logs/                       # Ansible execution logs
├── reference-files/                    # Reference documentation
├── tasks/                              # Reusable task definitions
└── tmpdir/                             # Temporary files directory
```

## Playbooks

### Core Installation Playbooks

#### `install_and_monitor_cluster.yaml`
**Purpose**: Complete OpenShift cluster installation with real-time monitoring

**Features**:
- Validates prerequisites and OpenShift installer
- Creates installation configuration from templates
- Starts cluster installation asynchronously
- Monitors installation progress with configurable intervals
- Validates cluster connectivity and readiness
- Gathers cluster information and credentials
- Creates comprehensive installation summary

**Usage**:
```bash
ansible-playbook -i inventory.yml \
  -e @group_vars/cluster/lab/all.yaml \
  -e @group_vars/env/lab/default-vault.yaml \
  -e @group_vars/env/lab/all.yaml \
  -e @secrets/lab/secrets.yaml \
  --vault-password-file=../all-clusters-resources/vault-password.txt \
  install_and_monitor_cluster.yaml -vvv
```

#### `prep_cluster_install.yaml`
**Purpose**: Cluster preparation, initialization, and prerequisite validation

**Features**:
- Validates system prerequisites
- Prepares installation directory
- Validates configuration files
- Sets up required directories and permissions
- Generates install-config.yaml from templates
- Configures cluster-specific variables
- Prepares for cluster installation


#### `validate_cluster_and_kubeconfig.yaml`
**Purpose**: Post-installation validation and kubeconfig management

**Features**:
- Validates cluster connectivity and health
- Checks node and operator status
- Backs up kubeconfig files with timestamps
- Generates cluster access information
- Creates user-friendly access guides
- Performs final health checks

### GitOps and Operator Playbooks

#### `install_gitops_operator.yaml`
**Purpose**: GitOps operator installation

**Features**:
- Installs OpenShift GitOps operator
- Configures operator settings
- Validates operator installation

#### `install_argocd_playbook.yaml`
**Purpose**: ArgoCD installation and configuration

**Features**:
- Installs ArgoCD using Helm charts
- Configures ArgoCD settings
- Sets up initial projects and applications

#### `init_gitops.yaml`
**Purpose**: GitOps initialization and setup

**Features**:
- Initializes GitOps repositories
- Configures GitOps workflows
- Sets up initial applications

### Utility Playbooks

#### `destroy_cluster.yaml`
**Purpose**: Cluster destruction and cleanup

**Features**:
- Destroys OpenShift cluster
- Cleans up resources
- Removes installation artifacts

#### `store_cluster_inventory`
**Purpose**: Cluster inventory storage and management

**Features**:
- Stores cluster information in Git
- Creates inventory files
- Exports cluster data for external use


## Configuration Management

### Variable Hierarchy

The configuration uses a hierarchical variable structure:

```
group_vars/
├── all.yaml                    # Global variables
├── cluster/
│   ├── all.yaml               # Default cluster variables
│   ├── lab/all.yaml           # Lab cluster variables
│   └── hub-lab/               # Hub lab cluster variables
└── env/
    └── lab/
        ├── all.yaml           # Lab environment variables
        └── default-vault.yaml # Lab environment secrets
```

### Key Configuration Files

#### `ansible.cfg`
Ansible configuration with optimized settings:
- Disabled host key checking for automation
- YAML output callback for better readability
- Vault password file configuration
- Logging configuration

#### `inventory.yml`
Main inventory file defining localhost as the control node:
```yaml
all:
  vars:
    ansible_python_interpreter: /usr/bin/python3.11
    ansible_connection: local
  hosts:
    localhost:
```

### Variable Categories

#### Global Variables (`group_vars/all.yaml`)
- Ansible configuration settings
- Default timeouts and retries
- Common paths and directories

#### Cluster Variables (`group_vars/cluster/<cluster>/all.yaml`)
- Cluster-specific configuration
- OpenShift version and settings
- vSphere configuration
- Network settings

#### Environment Variables (`group_vars/env/<env>/all.yaml`)
- Environment-specific settings
- Registry configurations
- Network policies
- Resource limits

## Roles

### Core Roles

#### `prep_cluster_install`
**Purpose**: Cluster preparation and prerequisite validation

**Tasks**:
- Validates system prerequisites
- Prepares installation directory
- Validates configuration files
- Sets up required directories
- Generates install-config.yaml from templates
- Configures cluster-specific variables

#### `install_and_monitor_cluster`
**Purpose**: Installation and monitoring

**Tasks**:
- Starts cluster installation
- Monitors installation progress
- Validates cluster readiness
- Gathers cluster information

#### `validate_cluster_and_kubeconfig`
**Purpose**: Cluster validation and kubeconfig management

**Tasks**:
- Validates cluster connectivity
- Checks node and operator status
- Backs up kubeconfig files
- Generates access information

### GitOps Roles

#### `install_gitops_operator`
**Purpose**: GitOps operator installation

**Tasks**:
- Installs OpenShift GitOps operator
- Configures operator settings
- Validates installation

#### `install_argocd`
**Purpose**: ArgoCD installation

**Tasks**:
- Installs ArgoCD using Helm
- Configures ArgoCD settings
- Sets up initial projects

#### `init_gitops`
**Purpose**: GitOps initialization

**Tasks**:
- Initializes GitOps repositories
- Configures workflows
- Sets up applications

### Utility Roles

#### `destroy_cluster`
**Purpose**: Cluster destruction

**Tasks**:
- Destroys OpenShift cluster
- Cleans up resources
- Removes artifacts

#### `store_cluster_inventory`
**Purpose**: Cluster inventory storage

**Tasks**:
- Stores cluster information
- Creates inventory files
- Exports cluster data

## Templates

### Configuration Templates

#### `install-config.yaml.j2`
OpenShift installation configuration template with variables for:
- Cluster name and base domain
- vSphere configuration
- Network settings
- Pull secrets and SSH keys

#### `gitops-operator-values.yaml`
GitOps operator Helm values template with:
- Operator configuration
- Resource limits
- Security settings

#### `deploy-helper-script.sh`
Deployment helper script template for:
- Automated deployments
- Configuration management
- Error handling

### Template Usage

Templates are processed during playbook execution and generate configuration files based on variables:

```yaml
- name: Generate install-config.yaml
  template:
    src: install-config.yaml.j2
    dest: "{{ install_dir }}/install-config.yaml"
    mode: '0600'
```

## Secrets Management

### Secrets Structure

```
secrets/
└── lab/                              # Lab environment secrets
    ├── secrets.yaml                  # Encrypted secrets file
    ├── id_ed25519_odfl              # SSH private key (Ed25519)
    ├── id_ed25519_odfl.pub          # SSH public key (Ed25519)
    ├── id_rsa_odfl                  # SSH private key (RSA)
    ├── id_rsa_odfl.pub              # SSH public key (RSA)
    └── archive/                      # Archived secrets
        ├── pull-secret.json         # Red Hat pull secret
        ├── pull-secret.yaml         # Pull secret in YAML format
        └── ssh_key.yml              # SSH key configuration
```

### Encrypted Secrets (`secrets.yaml`)

Contains encrypted sensitive data:
- vSphere credentials
- Red Hat pull secrets
- Certificate data
- API tokens

### SSH Keys

Multiple SSH key formats supported:
- **Ed25519**: Modern, secure key format
- **RSA**: Traditional key format for compatibility

### Secrets Usage

```bash
# Edit encrypted secrets
ansible-vault edit secrets/lab/secrets.yaml \
  --vault-password-file=../all-clusters-resources/vault-password.txt

# View encrypted secrets
ansible-vault view secrets/lab/secrets.yaml \
  --vault-password-file=../all-clusters-resources/vault-password.txt
```

## Usage Examples

### Complete Installation Workflow

#### Automated Scripts (Recommended)
```bash
# 1. Prepare cluster (includes initialization)
./010-run-prep-cluster-install.sh lab lab

# 2. Install and monitor cluster
./030-run-install-and-monitor.sh lab lab

# 3. Validate cluster (optional but recommended)
ansible-playbook -i inventory.yml \
  -e @group_vars/cluster/lab/all.yaml \
  -e @group_vars/env/lab/default-vault.yaml \
  -e @group_vars/env/lab/all.yaml \
  -e @secrets/lab/secrets.yaml \
  --vault-password-file=../all-clusters-resources/vault-password.txt \
  validate_cluster_and_kubeconfig.yaml
```

#### Manual Playbook Execution
```bash
# 1. Prepare cluster (includes initialization)
ansible-playbook -i inventory.yml \
  -e @group_vars/cluster/lab/all.yaml \
  -e @group_vars/env/lab/default-vault.yaml \
  -e @group_vars/env/lab/all.yaml \
  -e @secrets/lab/secrets.yaml \
  --vault-password-file=../all-clusters-resources/vault-password.txt \
  prep_cluster_install.yaml

# 2. Install and monitor cluster
ansible-playbook -i inventory.yml \
  -e @group_vars/cluster/lab/all.yaml \
  -e @group_vars/env/lab/default-vault.yaml \
  -e @group_vars/env/lab/all.yaml \
  -e @secrets/lab/secrets.yaml \
  --vault-password-file=../all-clusters-resources/vault-password.txt \
  install_and_monitor_cluster.yaml

# 3. Validate cluster
ansible-playbook -i inventory.yml \
  -e @group_vars/cluster/lab/all.yaml \
  -e @group_vars/env/lab/default-vault.yaml \
  -e @group_vars/env/lab/all.yaml \
  -e @secrets/lab/secrets.yaml \
  --vault-password-file=../all-clusters-resources/vault-password.txt \
  validate_cluster_and_kubeconfig.yaml
```

### GitOps Installation

```bash
# Install GitOps operator
ansible-playbook -i inventory.yml \
  -e @group_vars/cluster/lab/all.yaml \
  -e @group_vars/env/lab/default-vault.yaml \
  -e @group_vars/env/lab/all.yaml \
  -e @secrets/lab/secrets.yaml \
  --vault-password-file=../all-clusters-resources/vault-password.txt \
  install_gitops_operator.yaml

# Install ArgoCD
ansible-playbook -i inventory.yml \
  -e @group_vars/cluster/lab/all.yaml \
  -e @group_vars/env/lab/default-vault.yaml \
  -e @group_vars/env/lab/all.yaml \
  -e @secrets/lab/secrets.yaml \
  --vault-password-file=../all-clusters-resources/vault-password.txt \
  install_argocd_playbook.yaml
```

### Cluster Management

```bash
# Destroy cluster
ansible-playbook -i inventory.yml \
  -e @group_vars/cluster/lab/all.yaml \
  -e @group_vars/env/lab/default-vault.yaml \
  -e @group_vars/env/lab/all.yaml \
  -e @secrets/lab/secrets.yaml \
  --vault-password-file=../all-clusters-resources/vault-password.txt \
  destroy_cluster.yaml
```

## Troubleshooting

### Common Issues

#### Installation Failures
```bash
# Check installation logs
tail -f install-dir/.openshift_install.log

# Check Ansible logs
tail -f ansible-logs/ansible.log

# Validate configuration
ansible-playbook -i inventory.yml \
  -e @group_vars/cluster/lab/all.yaml \
  --check install_and_monitor_cluster.yaml
```

#### Validation Issues
```bash
# Check cluster status
export KUBECONFIG=install-dir/auth/kubeconfig
oc get nodes
oc get clusteroperators

# Check specific operator
oc describe clusteroperator authentication
```

#### Secrets Issues
```bash
# Test vault password
ansible-vault view secrets/lab/secrets.yaml \
  --vault-password-file=../all-clusters-resources/vault-password.txt

# Re-encrypt secrets
ansible-vault rekey secrets/lab/secrets.yaml
```

### Debug Commands

#### Verbose Output
```bash
# Maximum verbosity
ansible-playbook -i inventory.yml playbook.yaml -vvvv

# Check specific task
ansible-playbook -i inventory.yml playbook.yaml --tags specific_task -vvv
```

#### Configuration Validation
```bash
# Validate inventory
ansible-inventory -i inventory.yml --list

# Check variable resolution
ansible-inventory -i inventory.yml --list --yaml
```

## Integration

### With Execution Environment

```bash
# Using execution environment
ansible-navigator run install_and_monitor_cluster.yaml \
  --eei ocp-provision-ee:latest \
  -m stdout

# Using podman directly
podman run --rm -it \
  -v $(pwd):/runner/project:Z \
  -e KUBECONFIG=/runner/project/install-dir/auth/kubeconfig \
  ocp-provision-ee:latest \
  ansible-playbook /runner/project/install_and_monitor_cluster.yaml
```

### With CI/CD

```yaml
# Example CI/CD integration
- name: Install OpenShift Cluster
  ansible-playbook:
    playbook: install_and_monitor_cluster.yaml
    inventory: inventory.yml
    extra_vars:
      - "@group_vars/cluster/{{ cluster }}/all.yaml"
      - "@group_vars/env/{{ env }}/default-vault.yaml"
      - "@secrets/{{ cluster }}/secrets.yaml"
    vault_password_file: vault-password.txt
```

### With External Tools

```bash
# Export cluster information
ansible-playbook -i inventory.yml \
  -e @group_vars/cluster/lab/all.yaml \
  store_cluster_inventory

# Use with external monitoring
ansible-playbook -i inventory.yml \
  -e @group_vars/cluster/lab/all.yaml \
  validate_cluster_and_kubeconfig.yaml
```

---

## Support and Resources

### Official Documentation
- [Ansible Documentation](https://docs.ansible.com/)
- [OpenShift Documentation](https://docs.openshift.com/)
- [VMware vSphere Documentation](https://docs.vmware.com/en/VMware-vSphere/)

### Project Maintenance
- **Maintainer**: ODFL Platform Team
- **Last Updated**: December 2024
- **Version**: 1.0.0
- **License**: Internal Use Only