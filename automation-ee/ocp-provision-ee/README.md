# OpenShift Provisioning Execution Environment

A containerized execution environment specifically designed for OpenShift cluster installation, management, and day-2 operations on VMware vSphere using Installer-Provisioned Infrastructure (IPI).

> **Quick Start**: Run `./builder.sh` to build the execution environment, then use `podman run --rm -it ocp-provision-ee:latest /bin/bash` to launch an interactive session.

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Configuration Files](#configuration-files)
- [Building the Execution Environment](#building-the-execution-environment)
- [Environment-Specific Configurations](#environment-specific-configurations)
- [Usage Examples](#usage-examples)
- [Troubleshooting](#troubleshooting)
- [Archive](#archive)

## Overview

This execution environment provides a complete containerized solution with all necessary tools and dependencies for OpenShift cluster management. It's built on Red Hat's Ansible Automation Platform execution environment and includes:

### Key Components

- **OpenShift Tools**: openshift-install, oc, kubectl (v4.18.23)
- **Helm**: v3.16.3 for package management
- **Kustomize**: v5.5.0 for configuration management
- **Policy Generator**: v1.15.0 for Open Cluster Management
- **Ansible**: Complete automation platform with required collections
- **Python Dependencies**: All necessary Python packages for OpenShift management

### Included Ansible Collections

- **kubernetes.core**: Kubernetes and OpenShift management
- **community.hashi_vault**: HashiCorp Vault integration
- **community.general**: General purpose modules
- **ansible.scm**: Source control management

### Python Dependencies

- **selinux**: SELinux support
- **dnspython**: DNS resolution
- **psutil**: System monitoring
- **netaddr**: Network address manipulation
- **openshift**: OpenShift Python client
- **kubernetes**: Kubernetes Python client
- **pyyaml**: YAML processing
- **python-gitlab**: GitLab integration

### Base Image

- **Registry**: `registry.redhat.io/ansible-automation-platform-25/ee-supported-rhel9:latest`
- **OS**: Red Hat Enterprise Linux 9
- **Python**: 3.11
- **Architecture**: x86_64

## Quick Start

### 1. Build the Execution Environment
```bash
./builder.sh
```

### 2. Verify Installation
```bash
podman run --rm ocp-provision-ee:latest openshift-install version
podman run --rm ocp-provision-ee:latest oc version --client
podman run --rm ocp-provision-ee:latest helm version
```

### 3. Launch Interactive Environment
```bash
# From parent directory
./ee-bash.sh lab lab

# Or directly with podman
podman run --rm -it \
  -v $(pwd):/runner/project:Z \
  ocp-provision-ee:latest \
  /bin/bash
```

## Configuration Files

### Main Configuration

#### `execution-environment.yaml`
The primary execution environment definition file containing:

- **Dependencies**: Python packages and Ansible collections
- **System Packages**: Required RPM packages
- **Build Steps**: Tool installation and configuration
- **Environment Variables**: Tool versions and URLs

#### `builder.sh`
Automated build script that:

- Pulls the base image
- Builds the execution environment
- Tags the image appropriately
- Cleans up build context
- Provides build timing information

### Ansible Configuration Files

#### `files/ansible.cfg`
Default Ansible configuration with:

- **Inventory**: Default inventory settings
- **Host Key Checking**: Disabled for automation
- **Timeout Settings**: Optimized for OpenShift operations
- **Logging**: Comprehensive logging configuration

#### `files/ansible-customer.cfg`
Customer-specific configuration for:

- **Custom Registries**: Customer-specific registry settings
- **Authentication**: Customer authentication methods
- **Network Settings**: Customer network configurations

## Building the Execution Environment

### Automated Build Process

The `builder.sh` script handles the complete build process:

```bash
#!/bin/bash
# Build configuration
EE_NAME=ocp-provision-ee
EE_VERSION=1.0
EE_VERBOSITY=3

# Pull base image
podman pull registry.redhat.io/ansible-automation-platform-25/ee-supported-rhel9:latest

# Build execution environment
ansible-builder build --verbosity ${EE_VERBOSITY} --prune-images --tag ${EE_NAME}:${EE_VERSION} --tag ${EE_NAME}:latest
```

### Manual Build Process

```bash
# Clean previous builds
rm -rf context/

# Build with specific options
ansible-builder build \
  --verbosity 3 \
  --prune-images \
  --tag ocp-provision-ee:1.0 \
  --tag ocp-provision-ee:latest
```

### Build Steps

1. **Base Image Preparation**: Downloads Red Hat EE base image
2. **Dependencies Installation**: Installs Python packages and system dependencies
3. **Collection Installation**: Installs required Ansible collections
4. **Tool Installation**: Downloads and installs OpenShift tools, Helm, Kustomize
5. **Configuration**: Applies custom Ansible configurations
6. **Validation**: Verifies all tools are working correctly

### Build Configuration

The execution environment is built using the following configuration:

```yaml
version: 3
build_arg_defaults:
  ANSIBLE_GALAXY_CLI_COLLECTION_OPTS: '--upgrade'

dependencies:
  python_interpreter:
    python_path: /usr/bin/python3.11
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

### Build Output

- **Image Name**: `ocp-provision-ee:latest`
- **Image Size**: ~2-3GB (includes all tools and dependencies)
- **Registry**: Local Podman registry
- **Context Cleanup**: Automatic cleanup of build context

### Build Performance

- **Build Time**: 10-20 minutes (depending on network and system performance)
- **Cache Usage**: Base image and dependencies are cached for faster rebuilds
- **Parallel Downloads**: Multiple tools downloaded simultaneously
- **Layer Optimization**: Minimal layers for efficient storage

## Environment-Specific Configurations

### Customer Configuration (`execution-environment-customer.yaml`)

Customer-specific configuration for:

- **Custom Registries**: Customer-specific registry settings
- **Authentication**: Customer authentication methods
- **Network Settings**: Customer network configurations
- **Compliance**: Customer compliance requirements

## Usage Examples

### Interactive Development

```bash
# Launch interactive environment
podman run --rm -it \
  -v $(pwd):/runner/project:Z \
  -e KUBECONFIG=/runner/project/clusterconfig/auth/kubeconfig \
  ocp-provision-ee:latest \
  /bin/bash

# Inside container, verify tools
openshift-install version
oc version --client
helm version
kustomize version
ansible --version
```

### Development Workflow

```bash
# 1. Build the execution environment
./builder.sh

# 2. Test the build
podman run --rm ocp-provision-ee:latest openshift-install version

# 3. Launch development session
podman run --rm -it \
  -v $(pwd):/runner/project:Z \
  -e KUBECONFIG=/runner/project/clusterconfig/auth/kubeconfig \
  ocp-provision-ee:latest \
  /bin/bash

# 4. Inside container, work with your project
cd /runner/project
# Your project files are mounted here
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

### OpenShift Cluster Operations

```bash
# Generate install manifests
podman run --rm -it \
  -v $(pwd)/clusterconfig:/runner/project/clusterconfig:Z \
  ocp-provision-ee:latest \
  openshift-install create manifests --dir /runner/project/clusterconfig

# Create cluster
podman run --rm -it \
  -v $(pwd)/clusterconfig:/runner/project/clusterconfig:Z \
  ocp-provision-ee:latest \
  openshift-install create cluster --dir /runner/project/clusterconfig

# Wait for cluster completion
podman run --rm -it \
  -v $(pwd)/clusterconfig:/runner/project/clusterconfig:Z \
  -e KUBECONFIG=/runner/project/clusterconfig/auth/kubeconfig \
  ocp-provision-ee:latest \
  oc wait --for condition=Available=True clusteroperator/authentication --timeout=600s
```

### Advanced OpenShift Operations

```bash
# Generate ignition configs
podman run --rm -it \
  -v $(pwd)/clusterconfig:/runner/project/clusterconfig:Z \
  ocp-provision-ee:latest \
  openshift-install create ignition-configs --dir /runner/project/clusterconfig

# Destroy cluster
podman run --rm -it \
  -v $(pwd)/clusterconfig:/runner/project/clusterconfig:Z \
  ocp-provision-ee:latest \
  openshift-install destroy cluster --dir /runner/project/clusterconfig

# Gather bootstrap logs
podman run --rm -it \
  -v $(pwd)/clusterconfig:/runner/project/clusterconfig:Z \
  ocp-provision-ee:latest \
  openshift-install gather bootstrap --dir /runner/project/clusterconfig
```

### Helm Operations

```bash
# Install Helm chart
podman run --rm -it \
  -v $(pwd):/runner/project:Z \
  -e KUBECONFIG=/runner/project/clusterconfig/auth/kubeconfig \
  ocp-provision-ee:latest \
  helm install my-release ./charts/my-chart

# List Helm releases
podman run --rm -it \
  -v $(pwd):/runner/project:Z \
  -e KUBECONFIG=/runner/project/clusterconfig/auth/kubeconfig \
  ocp-provision-ee:latest \
  helm list
```

### Kustomize Operations

```bash
# Apply Kustomize configuration
podman run --rm -it \
  -v $(pwd):/runner/project:Z \
  -e KUBECONFIG=/runner/project/clusterconfig/auth/kubeconfig \
  ocp-provision-ee:latest \
  kustomize build /runner/project/overlays/production | kubectl apply -f -

# Build and save Kustomize output
podman run --rm -it \
  -v $(pwd):/runner/project:Z \
  ocp-provision-ee:latest \
  kustomize build /runner/project/overlays/production > /runner/project/manifests.yaml

# Validate Kustomize configuration
podman run --rm -it \
  -v $(pwd):/runner/project:Z \
  ocp-provision-ee:latest \
  kustomize build /runner/project/overlays/production --dry-run
```

### Policy Generator Operations

```bash
# Generate policies using Policy Generator
podman run --rm -it \
  -v $(pwd):/runner/project:Z \
  ocp-provision-ee:latest \
  /kustomize-plugins/policy.open-cluster-management.io/v1/policygenerator/PolicyGenerator \
  --config /runner/project/policy-config.yaml

# Apply generated policies
podman run --rm -it \
  -v $(pwd):/runner/project:Z \
  -e KUBECONFIG=/runner/project/clusterconfig/auth/kubeconfig \
  ocp-provision-ee:latest \
  kubectl apply -f /runner/project/policies/
```

## Troubleshooting

### Build Issues

#### Build Failures
```bash
# Check build logs
ansible-builder build --verbosity 3 2>&1 | tee build.log

# Clean and rebuild
rm -rf context/
ansible-builder build --prune-images

# Check build context
ls -la context/

# Verify base image
podman images | grep ee-supported-rhel9
```

#### Build Performance Issues
```bash
# Check available disk space
df -h

# Check available memory
free -h

# Monitor build process
podman system df
podman images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"
```

#### Registry Authentication
```bash
# Login to Red Hat registry
podman login registry.redhat.io

# Check authentication
podman pull registry.redhat.io/ansible-automation-platform-25/ee-supported-rhel9:latest
```

#### Network Issues
```bash
# Test network connectivity
podman run --rm ocp-provision-ee:latest curl -I https://mirror.openshift.com

# Check DNS resolution
podman run --rm ocp-provision-ee:latest nslookup registry.redhat.io

# Test specific endpoints
podman run --rm ocp-provision-ee:latest curl -I https://registry.redhat.io
podman run --rm ocp-provision-ee:latest curl -I https://pypi.org

# Check proxy settings
podman run --rm ocp-provision-ee:latest env | grep -i proxy
```

### Runtime Issues

#### Container Startup
```bash
# Check if image exists
podman images | grep ocp-provision-ee

# Inspect container
podman run --rm -it ocp-provision-ee:latest /bin/bash

# Check environment variables
podman run --rm ocp-provision-ee:latest env | grep -E "(OCP|HELM|KUSTOMIZE)"
```

#### Tool Verification
```bash
# Test OpenShift tools
podman run --rm ocp-provision-ee:latest openshift-install version
podman run --rm ocp-provision-ee:latest oc version --client
podman run --rm ocp-provision-ee:latest kubectl version --client

# Test other tools
podman run --rm ocp-provision-ee:latest helm version
podman run --rm ocp-provision-ee:latest kustomize version
```

#### Permission Issues
```bash
# Check SELinux context
ls -Z ./clusterconfig/

# Fix SELinux context
chcon -Rt svirt_sandbox_file_t ./clusterconfig/

# Test with proper context
podman run --rm -it \
  -v $(pwd)/clusterconfig:/runner/project/clusterconfig:Z \
  ocp-provision-ee:latest \
  /bin/bash
```

### Debug Commands

#### Container Debugging
```bash
# Interactive debugging
podman run --rm -it --entrypoint /bin/bash ocp-provision-ee:latest

# Check file system
podman run --rm ocp-provision-ee:latest ls -la /usr/local/bin/

# Check environment
podman run --rm ocp-provision-ee:latest printenv | sort

# Check tool versions and paths
podman run --rm ocp-provision-ee:latest which openshift-install
podman run --rm ocp-provision-ee:latest which oc
podman run --rm ocp-provision-ee:latest which helm
podman run --rm ocp-provision-ee:latest which kustomize
```

#### System Information
```bash
# Check container resource usage
podman stats

# Check container logs
podman logs <container_id>

# Inspect container configuration
podman inspect ocp-provision-ee:latest

# Check container layers
podman history ocp-provision-ee:latest
```

#### Ansible Debugging
```bash
# Test Ansible connectivity
podman run --rm -it \
  -v $(pwd):/runner/project:Z \
  ocp-provision-ee:latest \
  ansible all -m ping -i inventory

# Validate inventory
podman run --rm -it \
  -v $(pwd):/runner/project:Z \
  ocp-provision-ee:latest \
  ansible-inventory -i inventory --list
```


## Performance Optimization

### Build Optimization
```bash
# Use build cache
ansible-builder build --cache-from localhost/ocp-provision-ee:latest

# Parallel builds
ansible-builder build --parallel

# Skip unnecessary steps
ansible-builder build --skip-tags test
```

### Runtime Optimization
```bash
# Set resource limits
podman run --rm -it \
  --memory=4g \
  --cpus=2 \
  ocp-provision-ee:latest /bin/bash

# Use tmpfs for temporary files
podman run --rm -it \
  --tmpfs /tmp:rw,size=1g \
  ocp-provision-ee:latest /bin/bash
```

### Storage Optimization
```bash
# Clean up unused images
podman image prune -f

# Remove all unused containers and images
podman system prune -a -f

# Check storage usage
podman system df
```

## Security Considerations

### Image Security
- **Base Image**: Uses Red Hat's supported and security-patched base image
- **Dependencies**: All Python packages are from trusted sources
- **Tools**: OpenShift tools are downloaded from official Red Hat mirrors
- **Updates**: Regular updates recommended for security patches

### Runtime Security
- **SELinux**: Proper SELinux context with `:Z` mount option
- **User Permissions**: Runs with appropriate user permissions
- **Network Access**: Controlled network access for required endpoints
- **Secrets**: Proper handling of sensitive data in mounted volumes

## Support and Resources

### Official Documentation
- [Ansible Builder Documentation](https://ansible.readthedocs.io/projects/builder/)
- [OpenShift Documentation](https://docs.openshift.com/)
- [Red Hat Ansible Automation Platform](https://www.ansible.com/products/automation-platform)
- [Podman Documentation](https://docs.podman.io/)

### Community Resources
- [OpenShift Community](https://github.com/openshift)
- [Ansible Galaxy](https://galaxy.ansible.com/)
- [Red Hat Developer](https://developers.redhat.com/)

### Project Maintenance
- **Maintainer**: ODFL Platform Team
- **Last Updated**: December 2024
- **Version**: 1.0.0
- **License**: Internal Use Only.PlatformManagement`**: Platform management dependencies
- **`requirements.yaml`**: Standard dependency requirements

---

## Performance Optimization

### Build Optimization
```bash
# Use build cache
ansible-builder build --cache-from localhost/ocp-provision-ee:latest

# Parallel builds
ansible-builder build --parallel

# Skip unnecessary steps
ansible-builder build --skip-tags test
```

### Runtime Optimization
```bash
# Set resource limits
podman run --rm -it \
  --memory=4g \
  --cpus=2 \
  ocp-provision-ee:latest /bin/bash

# Use tmpfs for temporary files
podman run --rm -it \
  --tmpfs /tmp:rw,size=1g \
  ocp-provision-ee:latest /bin/bash
```

### Storage Optimization
```bash
# Clean up unused images
podman image prune -f

# Remove all unused containers and images
podman system prune -a -f

# Check storage usage
podman system df
```

## Security Considerations

### Image Security
- **Base Image**: Uses Red Hat's supported and security-patched base image
- **Dependencies**: All Python packages are from trusted sources
- **Tools**: OpenShift tools are downloaded from official Red Hat mirrors
- **Updates**: Regular updates recommended for security patches

### Runtime Security
- **SELinux**: Proper SELinux context with `:Z` mount option
- **User Permissions**: Runs with appropriate user permissions
- **Network Access**: Controlled network access for required endpoints
- **Secrets**: Proper handling of sensitive data in mounted volumes

## Support and Resources

### Official Documentation
- [Ansible Builder Documentation](https://ansible.readthedocs.io/projects/builder/)
- [OpenShift Documentation](https://docs.openshift.com/)
- [Red Hat Ansible Automation Platform](https://www.ansible.com/products/automation-platform)
- [Podman Documentation](https://docs.podman.io/)

### Community Resources
- [OpenShift Community](https://github.com/openshift)
- [Ansible Galaxy](https://galaxy.ansible.com/)
- [Red Hat Developer](https://developers.redhat.com/)

### Project Maintenance
- **Maintainer**: ODFL Platform Team
- **Last Updated**: December 2024
- **Version**: 1.0.0
- **License**: Internal Use Only