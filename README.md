# OpenShift vSphere IPI Installation Project

A comprehensive automation framework for OpenShift cluster installation, management, and day-2 operations on VMware vSphere using Installer-Provisioned Infrastructure (IPI).

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Prerequisites](#prerequisites)
- [Installation Scripts](#installation-scripts)
- [Execution Environment](#execution-environment)
- [Testing Tools](#testing-tools)
- [Day-2 Operations](#day-2-operations)
- [Configuration Management](#configuration-management)
- [Documentation](#documentation)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

## Overview

This project provides a complete automation framework for OpenShift cluster deployment on VMware vSphere using IPI (Installer-Provisioned Infrastructure). It includes:

- **Automated Installation**: Complete cluster installation with monitoring
- **Execution Environment**: Containerized Ansible environment with all required tools
- **Testing Framework**: Manifest generation and validation tools
- **Day-2 Operations**: Post-installation configuration and management
- **Configuration Management**: Centralized variable management and secrets handling
- **Comprehensive Documentation**: Detailed guides and troubleshooting information

## Quick Start

### 1. Build Execution Environment
```bash
cd automation-ee/ocp-provision-ee/
./builder.sh
```

### 2. Run Complete Installation
```bash
# Option A: Complete installation with monitoring (recommended)
./030-run-install-and-monitor.sh lab lab

# Option B: Step-by-step installation
# 1. Prepare cluster (prerequisite for step 2)
./010-run-prep-cluster-install.sh lab lab
# 2. Initialize cluster (depends on step 1)
./020-run-initialize-cluster.sh lab lab

# Option C: Install GitOps operator (standalone)
./040-run-install-gitops.sh lab lab
```

### 3. Test Manifest Generation
```bash
cd 00-ocp-test/
./00-test-manifest.sh --verbose
```

## Prerequisites

### System Requirements
- **Operating System**: Linux (RHEL 9+ recommended)
- **Memory**: Minimum 16GB RAM
- **Storage**: 100GB+ free disk space
- **Network**: Access to VMware vSphere and Red Hat registries

### Software Dependencies
- **Podman**: Container runtime for execution environment
- **Ansible**: Automation engine (included in execution environment)
- **OpenShift CLI**: OpenShift command-line tools (included in execution environment)

### VMware vSphere Requirements
- **vSphere Version**: 7.0+ recommended
- **Resource Pool**: Sufficient CPU, memory, and storage
- **Network**: Proper network configuration for cluster communication
- **Permissions**: Administrative access to vSphere environment

### Required Credentials
- **vSphere Credentials**: Username/password or API token
- **Red Hat Pull Secret**: For accessing Red Hat container images
- **SSH Key Pair**: For cluster node access
- **Certificate Files**: API and wildcard certificates (if using custom certs)

## Installation Scripts

### Core Installation Scripts

#### 1. Cluster Preparation (`010-run-prep-cluster-install.sh`)
Prepares the cluster environment and validates prerequisites. **Prerequisite for script 2**.

```bash
./010-run-prep-cluster-install.sh <cluster> <env>
# Example: ./010-run-prep-cluster-install.sh lab lab
```

**Features:**
- Validates prerequisites and dependencies
- Prepares cluster-specific configurations
- Sets up required directories and files

#### 2. Cluster Initialization (`020-run-initialize-cluster.sh`)
Initializes the cluster configuration and creates install-config.yaml. **Depends on script 1**.

```bash
./020-run-initialize-cluster.sh <cluster> <env>
# Example: ./020-run-initialize-cluster.sh lab lab
```

**Features:**
- Generates install-config.yaml from templates
- Configures cluster-specific variables
- Prepares for cluster installation

#### 3. Installation and Monitoring (`030-run-install-and-monitor.sh`)
Performs complete cluster installation with real-time monitoring. **Standalone script**.

```bash
./030-run-install-and-monitor.sh <cluster> <env>
# Example: ./030-run-install-and-monitor.sh lab lab
```

**Features:**
- Complete OpenShift cluster installation
- Real-time progress monitoring
- Automatic kubeconfig management
- Installation validation and reporting

#### 4. GitOps Installation (`040-run-install-gitops.sh`)
Installs GitOps operator using Helm charts. **Standalone script**.

```bash
./040-run-install-gitops.sh <cluster> <env>
# Example: ./040-run-install-gitops.sh lab lab
```

**Features:**
- GitOps operator installation
- Helm chart management
- Operator configuration
- Post-installation validation

### Interactive Tools

#### Execution Environment Launcher (`ee-bash.sh`)
Provides an interactive bash shell within the execution environment container.

```bash
./ee-bash.sh <cluster> <env>
# Example: ./ee-bash.sh lab lab
```

**Features:**
- Interactive development environment
- All OpenShift tools pre-installed
- Volume mounting for project files
- Comprehensive help system

**Usage Examples:**
```bash
# Show help
./ee-bash.sh -h

# Launch for lab environment
./ee-bash.sh lab lab

# Launch for production environment
./ee-bash.sh prod prod
```

## Execution Environment

### Overview
The execution environment (`ocp-provision-ee:latest`) is a containerized environment that includes all necessary tools for OpenShift cluster management.

### Building the Execution Environment
```bash
cd automation-ee/ocp-provision-ee/
./builder.sh
```

### Included Tools
- **OpenShift Installer**: openshift-install (v4.18.23)
- **OpenShift CLI**: oc, kubectl
- **Helm**: v3.16.3
- **Kustomize**: v5.5.0
- **Policy Generator**: v1.15.0
- **Ansible**: With required collections
- **Corporate Certificates**: Pre-configured for ODFL environment

### Container Features
- **Base Image**: Red Hat Ansible Automation Platform EE
- **Security**: SELinux context support
- **Networking**: Full network access for API calls
- **Volume Mounting**: Proper file access with `:Z` context

## Testing Tools

### Manifest Test Script (`00-ocp-test/00-test-manifest.sh`)
Tests OpenShift manifest generation in a controlled environment.

```bash
cd 00-ocp-test/
./00-test-manifest.sh [OPTIONS]
```

**Options:**
- `-h, --help`: Show comprehensive help
- `-v, --verbose`: Enable detailed logging
- `-d, --dry-run`: Preview operations without executing

**Features:**
- Clean test environment creation
- Prerequisites validation
- Manifest generation testing
- Multiple execution modes
- Comprehensive error handling

**Usage Examples:**
```bash
# Normal execution
./00-test-manifest.sh

# Verbose output
./00-test-manifest.sh --verbose

# Dry run (preview mode)
./00-test-manifest.sh --dry-run

# Show help
./00-test-manifest.sh -h
```

## Day-2 Operations

### Post-Installation Configuration

After cluster installation, several day-2 operations can be performed to configure the cluster for production use.

#### Certificate Management
```bash
# Install API and wildcard certificates
ansible-playbook -i inventory \
  -e @./group_vars/certs/cluster-[cluster]-certs.yaml \
  -e "cluster=[cluster]" \
  --vault-password-file=../all-clusters-resources/vault-password.txt \
  certs_deployment_playbook.yaml
```

#### Machine Configuration
```bash
# Include Chrony machine configs
ansible-playbook -i inventory \
  -e "cluster=[cluster]" \
  chrony_playbook.yaml

# Create MachineConfigPool for Infra Nodes
ansible-playbook -i inventory mcp_playbook.yaml

# Install machinesets
ansible-playbook -i inventory \
  -e @./group_vars/env/[env]/default-vault.yaml \
  -e @./group_vars/cluster/[cluster]/all.yaml \
  -e @./group_vars/env/[env]/all.yaml \
  -e "role_assigned=storage" \
  --vault-password-file=../all-clusters-resources/vault-password.txt \
  machinesets_playbook.yaml
```

#### LDAP Integration
```bash
# Enable LDAP authentication
ansible-playbook -i inventory \
  -e @./group_vars/env/[env]/default-vault.yaml \
  -e @./group_vars/env/[env]/all.yaml \
  --vault-password-file=../all-clusters-resources/vault-password.txt \
  ldap_playbook.yaml

# Enable LDAP group sync and role bindings
ansible-playbook -i inventory \
  -e @./group_vars/env/[env]/default-vault.yaml \
  -e @./group_vars/cluster/[cluster]/all.yaml \
  --vault-password-file=../all-clusters-resources/vault-password.txt \
  ldap_groupsync_playbook.yaml
```

#### Node Configuration
```bash
# Set up infra taints and tolerations
ansible-playbook -i inventory \
  -e @./group_vars/cluster/[cluster]/all.yaml \
  nodeconfig_playbook.yaml
```

#### Operator Management
```bash
# Configure OperatorHub for disconnected Quay
ansible-playbook -i inventory \
  -e @./group_vars/quay.yaml \
  -e "cluster=[cluster]" \
  --vault-password-file=../all-clusters-resources/vault-password.txt \
  operators_config_playbook.yaml

# Install specific operators
ansible-playbook -i inventory \
  -e "cluster=[cluster_name]" \
  -e "operator=[operator_name]" \
  -e "install_mode=[install_mode]" \
  -e "ns=[namespace]" \
  -e "channel=[channel]" \
  -e @./group_vars/cluster/[cluster]/all.yaml \
  operators_install_playbook.yaml

# Toggle operator update mode to Manual
ansible-playbook -i inventory \
  -e "cluster=[cluster]" \
  operator_toggle_playbook.yaml
```

#### GitOps and ArgoCD
```bash
# Install ArgoCD
ansible-playbook -i inventory \
  -e @./group_vars/cluster/[cluster]/all.yaml \
  -e @./group_vars/env/[environment]/all.yaml \
  -e @./group_vars/env/[environment]/default-vault.yaml \
  --vault-password-file=../all-clusters-resources/vault-password.txt \
  install_argocd_playbook.yaml

# Create ArgoCD projects
ansible-playbook -i inventory \
  -e @./group_vars/cluster/[cluster]/all.yaml \
  net_policy_argo_playbook.yaml
```

#### Additional Configurations
```bash
# Install Bitnami sealed secrets
ansible-playbook -i inventory \
  -e "cluster=[cluster]" \
  bitnami_playbook.yaml

# Deploy network policy template
ansible-playbook -i inventory \
  -e @./group_vars/cluster/[cluster]/all.yaml \
  network_policy_playbook.yaml

# Configure image registry
ansible-playbook -i inventory \
  -e "cluster=[cluster]" \
  image_registry_playbook.yaml

# Move monitoring pods to infra nodes
ansible-playbook -i inventory \
  -e "cluster=[cluster]" \
  monitoring_config_playbook.yaml
```

## Configuration Management

### Variable Structure
The project uses a hierarchical variable structure:

```
ansible/group_vars/
├── all.yaml                    # Global variables
├── cluster/
│   ├── lab/all.yaml           # Lab cluster variables
│   ├── dev/all.yaml            # Dev cluster variables
│   └── prod/all.yaml           # Prod cluster variables
├── env/
│   ├── lab/all.yaml            # Lab environment variables
│   ├── dev/all.yaml            # Dev environment variables
│   └── prod/all.yaml           # Prod environment variables
└── secrets/
    ├── lab/secrets.yaml        # Lab secrets (vaulted)
    ├── dev/secrets.yaml         # Dev secrets (vaulted)
    └── prod/secrets.yaml        # Prod secrets (vaulted)
```

### Secrets Management
All sensitive data is encrypted using Ansible Vault:

```bash
# Edit vaulted secrets
ansible-vault edit ansible/secrets/[env]/secrets.yaml \
  --vault-password-file=all-clusters-resources/vault-password.txt

# View vaulted secrets
ansible-vault view ansible/secrets/[env]/secrets.yaml \
  --vault-password-file=all-clusters-resources/vault-password.txt
```

### Certificate Management
Certificates are stored in vaulted files:

```bash
# Edit certificate files
ansible-vault edit ansible/group_vars/certs/cluster-[cluster]-certs.yaml \
  --vault-password-file=all-clusters-resources/vault-password.txt
```

### Pull Secret Management
```bash
# Update pull secret
ansible-vault edit ansible/group_vars/pull-secret.yaml \
  --vault-password-file=all-clusters-resources/vault-password.txt

# Apply pull secret to cluster
ansible-playbook -i inventory \
  -e cluster=[cluster] \
  -e @./group_vars/pull-secret.yaml \
  update_pullsecret_playbook.yaml \
  --vault-password-file=../all-clusters-resources/vault-password.txt
```

## General instructions

### All Plays in One

This section shows the command to run all the plays as one big playbook.
Or go to the next section to run individual plays to update, or check a config setting.

#### Install Certs First

```sh
ansible-playbook -i inventory \
-e @./group_vars/certs/cluster-[cluster]-certs.yaml \
-e "cluster=[cluster]" \
--vault-password-file=../all-clusters-resources/vault-password.txt \
certs_deployment_playbook.yaml
```

Wait for all initial nodes to be ready before moving on.
May need to login to the api with kubeadmin since system:admin will be logged out when masters are restarted

#### Finalize Cluster

After the certificates have been applied, and all nodes are back in ready state, log into the api with the kubeadmin username and password provided after the cluster has been initialized.

Update the KUBECONFIG environment variable with the logged in users's tokens:

```sh
export KUBECONFIG=~/.kube/config
```

There will be pauses during the builds, wait until the object just initiated by the playbook has completed before moving on.

The first pause is for the storage nodes, after the machineconfigs have been created. Wait until the storage nodes are up, and vmotion, if needed, the storage nodes before moving on.

Once storage nodes are vmotioned, continue the playbook.

```sh
ansible-playbook -i inventory \
-e @./group_vars/cluster/[cluster]/all.yaml \
-e @./group_vars/env/[env]/default-vault.yaml \
-e @./group_vars/env/[env]/all.yaml \
-e @./group_vars/quay.yaml \
--vault-password-file=../all-clusters-resources/vault-password.txt \
--tags ocp \
finalize_cluster.yaml
```

#### Building Quay Cluster

```sh
ansible-playbook -i inventory \
-e @./group_vars/cluster/[quay_cluster]/all.yaml \
-e @./group_vars/env/[env]]/default-vault.yaml \
-e @./group_vars/env/[env]/all.yaml \
--vault-password-file=../all-clusters-resources/vault-password.txt \
--tags quay \
finalize_cluster.yaml
```

#### Install ArgoCD Projects

Wait 5-10 minutes then run the ArgoCD Projects playbook: [Create ArgoCD Projects](#create-argocd-projects)

## Day 2: Post Initialization Instructions (Individual Playbooks)

Each section below contains the commands for installing the individual plays to finalize a cluster.
You will need to replace the [cluster] defined in each with the cluster you are building (for instance: dev).

### Installing api and wildcard certs

```sh
ansible-playbook -i inventory \
-e @./group_vars/certs/cluster-[cluster]-certs.yaml \
-e "cluster=[cluster]" \
certs_deployment_playbook.yaml \
--vault-password-file=../all-clusters-resources/vault-password.txt
```

### Include Chrony Machineconfigs

```sh
ansible-playbook -i inventory \
-e "cluster=[cluster]" \
chrony_playbook.yaml

### Create MachineConfigPool for Infra Nodes

```sh
ansible-playbook -i inventory mcp_playbook.yaml
```

### Installing machinesets

 When running this command you will be prompted for the type of machinesets to be created.
 Defaults to worker, but to build infra machinesets, type: `infra`

```sh
ansible-playbook -i inventory \
-e @./group_vars/env/[env]/default-vault.yaml \
-e @./group_vars/cluster/[cluster]/all.yaml \
-e @./group_vars/env/[env]/all.yaml \
-e "role_assigned=storage" \
--vault-password-file=../all-clusters-resources/vault-password.txt \
machinesets_playbook.yaml
```

### Enable LDAP

```sh
ansible-playbook -i inventory \
-e @./group_vars/env/[env]/default-vault.yaml \
-e @./group_vars/env/[env]/all.yaml \
--vault-password-file=../all-clusters-resources/vault-password.txt \
ldap_playbook.yaml
```

### Enable LDAP Group Sync and role bindings

```sh
ansible-playbook -i inventory \
-e @./group_vars/env/[env]/default-vault.yaml \
-e @./group_vars/cluster/[cluster]/all.yaml \
--vault-password-file=../all-clusters-resources/vault-password.txt \
ldap_groupsync_playbook.yaml
```

### Setting up Infra Taints and Tolerations

**Note**: Make sure all infra nodes are up and provisioned before running this step.

```sh
ansible-playbook -i inventory \
-e @./group_vars/cluster/[cluster]/all.yaml \
nodeconfig_playbook.yaml
```

### Configure OperatorHub to Pull from Disconnected Quay

```sh
ansible-playbook -i inventory \
-e @./group_vars/quay.yaml \
-e "cluster=[cluster]" \
--vault-password-file=../all-clusters-resources/vault-password.txt \
operators_config_playbook.yaml
```

### Configure Update Services to pull from Disconnected Quay

```sh
ansible-playbook -i inventory \
-e "cluster=[cluster]" \
update_svs_playbook.yaml
```

### Install an Operator

Pass the variables, depending on the operator, to the playbook.
Variables to pass are:

- Operator Name
- Install Mode (SingleNamespace or AllNamespaces or OwnNamespaces)
- Namespace
- Channel

The above information can be gathered by grepping the information from the packagemanifest.
Defaults to SingleNamespace. If you put AllNamespaces the results will show installed in all namespaces.

To get the required variables grep from the packagemanifest. See next step.

#### Example of grep for Operator Information

This should be done for the following information:

- Install Modes (keyword: modes)
- Suggested Namespace(s) (keyword: suggested)
  - If none is provided, then use the default namespace: openshift-operators
- Install Channel: (keyword: channel)

```sh
oc describe packagemanifest openshift-gitops | grep -A10 -i modes
      Install Modes:
        Supported:  false
        Type:       OwnNamespace
        Supported:  false
        Type:       SingleNamespace
        Supported:  false
        Type:       MultiNamespace
        Supported:  true
        Type:       AllNamespaces
```

#### Run playbook

```sh
ansible-playbook -i inventory \
-e "cluster=[cluster_name]" \
-e "operator=[operator_name]" \
-e "install_mode=[install_mode]" \
-e "ns=[namespace]" \
-e "channel=[channel]" \
-e @./group_vars/cluster/[cluster]/all.yaml \
operators_install_playbook.yaml
```

#### Configs for Operators

- Operator: odf-operator
  - install_mode: OwnNamespace
  - ns: openshift-storage
  - channel: stable-4.12
- Operator: local-storage-operator
  - install_mode: OwnNamespace
  - ns: openshift-local-storage
  - channel: stable
- Operator: openshift-gitops-operator
  - install_mode: AllNamespaces
  - ns: openshift-operators
  - channel: latest
- Operator: openshift-pipelines-operator-rh
  - install_mode: AllNamespaces
  - ns: openshift-operators
  - channel: latest
- Operator: cluster-logging
  - install_mode: OwnNamespace
  - ns: openshift-logging
  - channel: stable
- Operator: elasticsearch-operator
  - install_mode: OwnNamespace
  - ns: openshift-operators-redhat
  - channel: stable
- Operator: openshift-cert-manager-operator
  - install_mode: AllNamespaces
  - ns: cert-manager-operator
  - channel: stable-v1

### Toggle Operator Update Mode

Run the following playbook to set all Operators to Manual Update mode

```sh
ansible-playbook -i inventory \
-e "cluster=[cluster]" \
operator_toggle_playbook.yaml
```

### Install ArgoCD

Need to update default-vault.yaml (ansible-vault edit) with the ArgoCD Service Account password, using the username as the key.

```sh
ansible-playbook -i inventory \
-e @./group_vars/cluster/[cluster]/all.yaml \
-e @./group_vars/env/[environment]/all.yaml \
-e @./group_vars/env/[environment]/default-vault.yaml \
--vault-password-file=../all-clusters-resources/vault-password.txt \
install_argocd_playbook.yaml
```

### Install Bitnami

```sh
ansible-playbook -i inventory \
-e "cluster=[cluster]" \
bitnami_playbook.yaml
```

## Documentation

### Comprehensive Guides
- **[DEPLOYMENT-SUMMARY.md](./DEPLOYMENT-SUMMARY.md)**: Complete deployment overview
- **[TECHNICAL-SUMMARY.md](./TECHNICAL-SUMMARY.md)**: Technical implementation details
- **[EXECUTIVE-SUMMARY.md](./EXECUTIVE-SUMMARY.md)**: Executive-level project summary
- **[USER-GUIDE-SUMMARY.md](./USER-GUIDE-SUMMARY.md)**: User-focused guide
- **[INSTALLATION-MONITORING-GUIDE.md](./INSTALLATION-MONITORING-GUIDE.md)**: Installation monitoring procedures
- **[GITOPS-INSTALLATION-GUIDE.md](./GITOPS-INSTALLATION-GUIDE.md)**: GitOps operator installation guide

### Script Documentation
- **[ee-bash.sh Usage Guide](./README-ee-bash.sh.usage.md)**: Execution environment launcher documentation
- **[00-ocp-test/README.md](./00-ocp-test/README.md)**: Manifest testing tool documentation

### Project Structure
```
openshift-vsphere-ipi-install/
├── ansible/                          # Ansible playbooks and configurations
│   ├── group_vars/                   # Variable definitions
│   ├── roles/                        # Ansible roles
│   ├── secrets/                      # Encrypted secrets
│   └── templates/                    # Configuration templates
├── automation-ee/                    # Execution environment
│   └── ocp-provision-ee/            # Container build files
├── 00-ocp-test/                     # Testing tools
├── all-clusters-resources/          # Cluster-specific resources
├── day2/                            # Day-2 operations
└── *.sh                             # Installation scripts
```

## Troubleshooting

### Common Issues

#### Execution Environment Problems
```bash
# Check if execution environment exists
podman images | grep ocp-provision-ee

# Build execution environment if missing
cd automation-ee/ocp-provision-ee/
./builder.sh
```

#### Installation Failures
```bash
# Check installation logs
tail -f 030-install-output.out

# Validate cluster status
./ee-bash.sh lab lab
# Inside container:
oc get nodes
oc get clusteroperators
```

#### Manifest Generation Issues
```bash
# Test manifest generation
cd 00-ocp-test/
./00-test-manifest.sh --verbose --dry-run
```

#### Permission Issues
```bash
# Check SELinux context
ls -Z ./ansible/
ls -Z ./all-clusters-resources/

# Fix SELinux context if needed
chcon -Rt svirt_sandbox_file_t ./ansible/
chcon -Rt svirt_sandbox_file_t ./all-clusters-resources/
```

### Debugging Commands

#### Check Cluster Status
```bash
# Using execution environment
./ee-bash.sh lab lab
# Inside container:
oc get nodes
oc get clusteroperators
oc get pods -A
```

#### Validate Configuration
```bash
# Check Ansible configuration
ansible-inventory -i inventory.yml --list

# Validate playbooks
ansible-playbook --check install_and_monitor_cluster.yaml
```

#### Log Analysis
```bash
# View installation logs
tail -f 030-install-output.out
tail -f 040-gitops-output.out

# Check Podman logs
podman logs <container_id>
```

### Getting Help

#### Script Help
```bash
# Get help for any script
./ee-bash.sh -h
./00-test-manifest.sh -h
```

#### Verbose Output
```bash
# Enable verbose output for debugging
./00-test-manifest.sh --verbose
./030-run-install-and-monitor.sh lab lab 2>&1 | tee -a verbose-install.log
```

## Contributing

### Development Workflow

1. **Fork the repository**
2. **Create a feature branch**
3. **Make changes with proper documentation**
4. **Test changes thoroughly**
5. **Submit a pull request**

### Code Standards

- **Shell Scripts**: Follow bash best practices with proper error handling
- **Ansible**: Use consistent variable naming and role structure
- **Documentation**: Update README files for any new features
- **Testing**: Add tests for new functionality

### Testing Requirements

- **Execution Environment**: Test with built execution environment
- **Multiple Environments**: Test with lab, dev, and prod configurations
- **Error Handling**: Verify proper error messages and recovery
- **Documentation**: Ensure all new features are documented

### Security Considerations

- **Secrets Management**: Never commit unencrypted secrets
- **Certificate Handling**: Use Ansible Vault for all certificates
- **Access Control**: Follow principle of least privilege
- **Audit Trail**: Maintain logs for all operations

---

## Support and Resources

### Official Documentation
- [OpenShift Documentation](https://docs.openshift.com/)
- [Ansible Documentation](https://docs.ansible.com/)
- [VMware vSphere Documentation](https://docs.vmware.com/en/VMware-vSphere/)

### Community Resources
- [OpenShift Community](https://github.com/openshift)
- [Ansible Galaxy](https://galaxy.ansible.com/)
- [Red Hat Developer](https://developers.redhat.com/)

### Project Maintenance
- **Maintainer**: ODFL Platform Team
- **Last Updated**: October 2024
- **Version**: 1.0.0
- **License**: Internal Use Only
