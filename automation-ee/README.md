# OpenShift vSphere IPI Automation Execution Environment

A comprehensive containerized execution environment for OpenShift cluster installation, management, and day-2 operations on VMware vSphere using Installer-Provisioned Infrastructure (IPI).

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Project Structure](#project-structure)
- [Execution Environment](#execution-environment)
- [Prerequisites](#prerequisites)
- [Building the Execution Environment](#building-the-execution-environment)
- [Usage Examples](#usage-examples)
- [Configuration](#configuration)
- [Troubleshooting](#troubleshooting)
- [Documentation](#documentation)
- [Contributing](#contributing)

## Overview

This automation execution environment provides a complete containerized solution for OpenShift cluster deployment and management. It includes all necessary tools, dependencies, and configurations required for:

- **OpenShift Cluster Installation**: Complete IPI installation on VMware vSphere
- **Cluster Management**: Day-2 operations and configuration management
- **GitOps Operations**: ArgoCD and GitOps operator management
- **Testing and Validation**: Manifest generation and cluster validation
- **Security**: Encrypted secrets management and certificate handling

### Key Features

- **Containerized Environment**: All tools pre-installed and configured
- **OpenShift Tools**: openshift-install, oc, kubectl (v4.18.23)
- **Helm Support**: Helm v3.16.3 for chart management
- **Kustomize Integration**: v5.5.0 for configuration management
- **Policy Generator**: v1.15.0 for Open Cluster Management
- **Ansible Collections**: Complete set of required collections
- **Security**: SELinux support and proper file permissions
- **Corporate Integration**: Pre-configured for ODFL environment

## Quick Start

### 1. Install Prerequisites
```bash
cd prep/
./install_ansible_tools.sh
```

### 2. Build Execution Environment
```bash
cd ocp-provision-ee/
./builder.sh
```

### 3. Launch Interactive Environment
```bash
# From the parent directory
./ee-bash.sh lab lab
```

### 4. Run Cluster Installation
```bash
# Complete installation with monitoring
./030-run-install-and-monitor.sh lab lab

# Or step-by-step installation
./010-run-prep-cluster-install.sh lab lab
./020-run-initialize-cluster.sh lab lab
```

## Project Structure

```
automation-ee/
├── README.md                           # This file - Main documentation
├── ocp-provision-ee/                   # Main execution environment
│   ├── README.md                       # EE-specific documentation
│   ├── builder.sh                      # Automated build script
│   ├── clean-build-env.sh              # Build environment cleanup
│   ├── execution-environment.yaml      # Primary EE definition file
│   ├── execution-environment-customer.yaml  # Customer-specific config
│   ├── files/                          # Configuration files
│   │   ├── ansible.cfg                 # Default Ansible configuration
│   │   └── ansible-customer.cfg        # Customer-specific Ansible config
│   ├── archive/                        # Historical configurations
│   │   ├── execution-environment-*.yaml # Historical EE definitions
│   │   ├── ansible.cfg.*               # Historical Ansible configs
│   │   ├── requirements.yaml.*         # Historical requirements
│   │   └── build_ee.*.bash             # Historical build scripts
│   ├── automation-hub-token.url        # Red Hat Automation Hub token
│   └── builder.out                     # Build output log
├── prep/                               # Prerequisites and setup
│   ├── README.md                       # Prerequisites documentation
│   └── install_ansible_tools.sh       # Automated prerequisites installer
├── README-execution-environment-guide.md  # Complete EE guide (build, mount, run)
└── ocp-provision-ee.tgz               # Packaged execution environment
```

### Directory Descriptions

#### **Root Level Files**
- **`README.md`**: Main documentation for the automation execution environment
- **`README-ocp-ee.md`**: Guide for integrating OpenShift tools in execution environments
- **`README-build-ee-w-ocp.md`**: Detailed instructions for building execution environments with OpenShift tools
- **`README-secrets-mount.md`**: Guide for properly mounting secrets into containers
- **`ocp-provision-ee.tgz`**: Packaged execution environment for distribution

#### **`ocp-provision-ee/` - Main Execution Environment**
- **`README.md`**: Detailed documentation for the execution environment
- **`builder.sh`**: Automated build script with timing and cleanup
- **`clean-build-env.sh`**: Script to clean build environment and artifacts
- **`execution-environment.yaml`**: Primary execution environment definition
- **`execution-environment-customer.yaml`**: Customer-specific configuration
- **`automation-hub-token.url`**: Red Hat Automation Hub authentication token
- **`builder.out`**: Build process output and logs

#### **`ocp-provision-ee/files/` - Configuration Files**
- **`ansible.cfg`**: Default Ansible configuration with optimized settings
- **`ansible-customer.cfg`**: Customer-specific Ansible configuration

#### **`ocp-provision-ee/archive/` - Historical Configurations**
Contains historical versions and alternative configurations:
- **Execution Environment Definitions**: Various historical EE configurations
- **Ansible Configurations**: Historical Ansible config files
- **Requirements Files**: Historical dependency requirements
- **Build Scripts**: Alternative build approaches and scripts

#### **`prep/` - Prerequisites and Setup**
- **`README.md`**: Comprehensive prerequisites documentation
- **`install_ansible_tools.sh`**: Automated installer for all required tools

### Key Configuration Files

#### **Execution Environment Definition** (`execution-environment.yaml`)
```yaml
version: 3
build_arg_defaults:
  ANSIBLE_GALAXY_CLI_COLLECTION_OPTS: '--upgrade'
dependencies:
  galaxy:
    collections:
      - name: kubernetes.core
      - name: community.hashi_vault
      - name: community.general
      - name: ansible.scm
  python:
    - selinux
    - dnspython
    - psutil
    - netaddr
    - openshift
    - kubernetes
    - pyyaml
    - python-gitlab
  system:
    - findutils [platform:rpm]
    - systemd-devel [platform:rpm]
    - python3.11-devel [platform:rpm]
    - gcc [platform:rpm]
```

#### **Build Script** (`builder.sh`)
- Automated build process with timing
- Base image pulling and caching
- Context cleanup and optimization
- Image tagging and versioning

#### **Prerequisites Installer** (`prep/install_ansible_tools.sh`)
- System package installation (Python, Podman, Git)
- Python package management
- Ansible tools installation
- PATH configuration
- Version verification

### File Naming Conventions

- **`execution-environment*.yaml`**: Execution environment definitions
- **`ansible*.cfg`**: Ansible configuration files
- **`requirements*.yaml`**: Python/Ansible dependency requirements
- **`build*.sh`**: Build and setup scripts
- **`install*.sh`**: Installation and setup scripts
- **`clean*.sh`**: Cleanup and maintenance scripts

## Execution Environment

### Base Image
- **Registry**: `registry.redhat.io/ansible-automation-platform-25/ee-supported-rhel9:latest`
- **OS**: Red Hat Enterprise Linux 9
- **Python**: 3.11
- **Package Manager**: microdnf

### Included Tools

| Tool | Version | Purpose |
|------|---------|---------|
| openshift-install | 4.18.23 | OpenShift cluster installer |
| oc | 4.18.23 | OpenShift CLI |
| kubectl | 4.18.23 | Kubernetes CLI |
| helm | 3.16.3 | Helm package manager |
| kustomize | 5.5.0 | Configuration management |
| PolicyGenerator | 1.15.0 | Open Cluster Management |
| ansible | Latest | Automation engine |
| ansible-vault | Latest | Secrets management |

### Ansible Collections

- `kubernetes.core` - Kubernetes and OpenShift management
- `community.hashi_vault` - HashiCorp Vault integration
- `community.general` - General purpose modules
- `ansible.scm` - Source control management

### Python Dependencies

- `selinux` - SELinux support
- `dnspython` - DNS resolution
- `psutil` - System monitoring
- `netaddr` - Network address manipulation
- `openshift` - OpenShift Python client
- `kubernetes` - Kubernetes Python client
- `pyyaml` - YAML processing
- `python-gitlab` - GitLab integration

## Prerequisites

### System Requirements
- **Operating System**: Linux (RHEL 9+ recommended)
- **Memory**: Minimum 8GB RAM
- **Storage**: 20GB+ free disk space
- **Network**: Access to Red Hat registries and VMware vSphere

### Software Dependencies
- **Podman**: Container runtime (latest version)
- **Python 3.11**: Python runtime
- **Git**: Version control system
- **ansible-builder**: ≥3.0.0 (installed by prep script)
- **ansible-navigator**: ≥2.16.0 (installed by prep script)

### VMware vSphere Requirements
- **vSphere Version**: 7.0+ recommended
- **Resource Pool**: Sufficient CPU, memory, and storage
- **Network**: Proper network configuration
- **Permissions**: Administrative access to vSphere

## Building the Execution Environment

### Automated Build
```bash
cd ocp-provision-ee/
./builder.sh
```

### Manual Build
```bash
cd ocp-provision-ee/
ansible-builder build --verbosity 3 --prune-images --tag ocp-provision-ee:1.0 --tag ocp-provision-ee:latest
```

### Build Process
1. **Base Image Pull**: Downloads Red Hat EE base image
2. **Dependencies**: Installs Python packages and system dependencies
3. **Collections**: Installs Ansible collections
4. **Tools**: Downloads and installs OpenShift tools, Helm, Kustomize
5. **Configuration**: Applies custom configurations
6. **Validation**: Verifies all tools are working correctly

### Build Output
- **Image Name**: `ocp-provision-ee:latest`
- **Image Size**: ~2-3GB (includes all tools)
- **Registry**: Local Podman registry

## Usage Examples

### Interactive Development Environment
```bash
# Launch interactive bash shell
./ee-bash.sh lab lab

# Inside container, you have access to all tools:
openshift-install version
oc version --client
helm version
kustomize version
ansible --version
```

### Running Ansible Playbooks
```bash
# Using ansible-navigator
ansible-navigator run playbooks/install-cluster.yml \
  --eei ocp-provision-ee:latest \
  -m stdout

# Using podman directly
podman run --rm -it \
  -v $(pwd):/runner/project:Z \
  -e KUBECONFIG=/runner/project/clusterconfig/auth/kubeconfig \
  ocp-provision-ee:latest \
  ansible-playbook /runner/project/playbooks/install-cluster.yml
```

### Cluster Installation
```bash
# Complete installation
./030-run-install-and-monitor.sh lab lab

# Step-by-step installation
./010-run-prep-cluster-install.sh lab lab
./020-run-initialize-cluster.sh lab lab
```

### GitOps Operations
```bash
# Install GitOps operator
./040-run-install-gitops.sh lab lab

# Using Helm directly
./ee-bash.sh lab lab
# Inside container:
helm install argocd ./charts/argocd
```

## Configuration

### Environment-Specific Configurations

The execution environment supports multiple configurations:

- **`execution-environment.yaml`**: Default configuration
- **`execution-environment-customer.yaml`**: Customer-specific configuration

### Ansible Configuration

Configuration files are included in the `files/` directory:

- **`ansible.cfg`**: Default Ansible configuration
- **`ansible-customer.cfg`**: Customer-specific settings

### Volume Mounting

For proper file access and security:

```bash
# Mount with SELinux context
podman run -v $(pwd):/runner/project:Z ocp-provision-ee:latest

# Mount specific directories
podman run \
  -v $(pwd)/clusterconfig:/runner/project/clusterconfig:Z \
  -v $(pwd)/playbooks:/runner/project/playbooks:Z \
  ocp-provision-ee:latest
```

## Troubleshooting

### Common Issues

#### Build Failures
```bash
# Check build logs
ansible-builder build --verbosity 3 2>&1 | tee build.log

# Clean and rebuild
rm -rf context/
ansible-builder build --prune-images
```

#### Container Issues
```bash
# Check if image exists
podman images | grep ocp-provision-ee

# Inspect container
podman run --rm -it ocp-provision-ee:latest /bin/bash

# Check tool versions
podman run --rm ocp-provision-ee:latest openshift-install version
```

#### Permission Issues
```bash
# Check SELinux context
ls -Z ./clusterconfig/

# Fix SELinux context
chcon -Rt svirt_sandbox_file_t ./clusterconfig/
```

#### Network Issues
```bash
# Test registry access
podman pull registry.redhat.io/ansible-automation-platform-25/ee-supported-rhel9:latest

# Check authentication
podman login registry.redhat.io
```

### Debug Commands

#### Container Debugging
```bash
# Interactive debugging
podman run --rm -it --entrypoint /bin/bash ocp-provision-ee:latest

# Check environment
podman run --rm ocp-provision-ee:latest env | grep -E "(OCP|HELM|KUSTOMIZE)"

# Test tool functionality
podman run --rm ocp-provision-ee:latest openshift-install version
```

#### Ansible Debugging
```bash
# Verbose Ansible output
ansible-playbook --check -vvv playbook.yml

# Test connectivity
ansible all -m ping -i inventory

# Validate configuration
ansible-inventory -i inventory --list
```

## Documentation

### Additional Documentation

- **[ocp-provision-ee/README.md](./ocp-provision-ee/README.md)**: Execution environment specific documentation
- **[prep/README.md](./prep/README.md)**: Prerequisites and setup guide
- **[README-execution-environment-guide.md](./README-execution-environment-guide.md)**: Complete execution environment guide (build, mount, run)

### Related Documentation

- **[Parent Project README](../README.md)**: Main project documentation
- **[Installation Scripts](../README.md#installation-scripts)**: Installation script documentation
- **[Day-2 Operations](../README.md#day-2-operations)**: Post-installation operations

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
- **Multiple Configurations**: Test with different environment configs
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
- [Ansible Builder Documentation](https://ansible.readthedocs.io/projects/builder/)
- [VMware vSphere Documentation](https://docs.vmware.com/en/VMware-vSphere/)

### Community Resources
- [OpenShift Community](https://github.com/openshift)
- [Ansible Galaxy](https://galaxy.ansible.com/)
- [Red Hat Developer](https://developers.redhat.com/)

### Project Maintenance
- **Maintainer**: ODFL Platform Team
- **Last Updated**: December 2024
- **Version**: 1.0.0
- **License**: Internal Use Only