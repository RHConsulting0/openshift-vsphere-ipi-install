# OpenShift Execution Environment Complete Guide

A comprehensive guide for building, configuring, and using Ansible execution environments with OpenShift tools for cluster installation and management.

## Table of Contents

- [Overview](#overview)
- [Understanding Execution Environments](#understanding-execution-environments)
- [Building Execution Environments with OpenShift Tools](#building-execution-environments-with-openshift-tools)
- [Mounting Secrets and Configuration Files](#mounting-secrets-and-configuration-files)
- [Running Playbooks and Commands](#running-playbooks-and-commands)
- [Security Considerations](#security-considerations)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

## Overview

This guide combines three essential aspects of working with Ansible execution environments for OpenShift:

1. **Building execution environments** with OpenShift tools pre-installed
2. **Understanding execution environments** as containerized automation platforms
3. **Mounting secrets and configuration files** securely into containers

## Understanding Execution Environments

### What is an Ansible Execution Environment?

An execution environment (EE) is an OCI image built with **ansible-builder**. It's essentially a container with:

- **Ansible Core**: The automation engine
- **Collections**: Any Ansible collections you specify
- **System Packages**: Any system or Python packages you install
- **Custom Tools**: Any binaries you want (including `openshift-install`)

### Key Benefits

- **Reproducible Environment**: Same tools and versions every time
- **Portability**: Works across different host systems
- **Isolation**: Clean, isolated environment for automation
- **Customization**: Include any tools or dependencies needed

### Why Use Execution Environments for OpenShift?

- **Consistency**: Same OpenShift tools across all environments
- **Version Control**: Pin specific versions of OpenShift tools
- **Dependency Management**: Handle all Python and system dependencies
- **Security**: Isolated environment with proper permissions

## Building Execution Environments with OpenShift Tools

### Method 1: Complete Execution Environment Definition

Create a comprehensive `execution-environment.yml`:

```yaml
version: 3
build_arg_defaults:
  EE_BASE_IMAGE: registry.redhat.io/ansible-automation-platform-25/ee-supported-rhel9:latest
  EE_BUILDER_IMAGE: registry.redhat.io/ansible-automation-platform-25/ansible-builder-rhel9:latest

dependencies:
  python:  # Python libraries your playbooks need
    - openshift
    - kubernetes
    - pyyaml
  system:  # System packages installed by microdnf
    - tar
    - gzip
    - curl

additional_build_steps:
  prepend:
    - |
      # Install OpenShift installer + client
      INSTALLER_VERSION=4.18.0
      INSTALLER_URL="https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${INSTALLER_VERSION}/openshift-install-linux.tar.gz"
      CLIENT_URL="https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${INSTALLER_VERSION}/openshift-client-linux.tar.gz"

      microdnf update -y && microdnf install -y tar gzip curl && microdnf clean all

      curl -fSL "${INSTALLER_URL}" -o /tmp/openshift-install.tar.gz
      curl -fSL "${CLIENT_URL}" -o /tmp/openshift-client.tar.gz

      tar -C /usr/local/bin -xzf /tmp/openshift-install.tar.gz openshift-install
      tar -C /usr/local/bin -xzf /tmp/openshift-client.tar.gz oc kubectl

      chmod +x /usr/local/bin/openshift-install /usr/local/bin/oc /usr/local/bin/kubectl
      rm -rf /tmp/*.tar.gz
  append:
    - |
      # Default to bash for interactive debugging
      CMD ["/bin/bash"]
```

### Method 2: Minimal Addition to Existing EE

Add OpenShift tools to an existing execution environment:

```yaml
version: 1
build_arg_defaults:
  EE_BASE_IMAGE: 'registry.redhat.io/ansible-automation-platform-25/ee-supported-rhel9:latest'

additional_build_steps:
  append:
    - RUN curl -L https://mirror.openshift.com/pub/openshift-v4/clients/ocp/4.18.0/openshift-install-linux.tar.gz \
      -o /tmp/openshift-install.tar.gz \
      && tar -C /usr/local/bin -xzf /tmp/openshift-install.tar.gz openshift-install \
      && chmod +x /usr/local/bin/openshift-install \
      && rm -f /tmp/openshift-install.tar.gz
```

### How the Build Process Works

1. **Base Image**: Uses Red Hat's supported EE base image
2. **Dependencies**: Installs Python packages and system dependencies
3. **Tool Installation**: Downloads and installs OpenShift tools
4. **Permissions**: Sets proper executable permissions
5. **Cleanup**: Removes temporary files to reduce image size

### Building the Execution Environment

```bash
# Build with ansible-builder
ansible-builder build -t my-ee-image:latest -f execution-environment.yml

# Or use the automated build script
./builder.sh
```

This produces a container image with all OpenShift tools included and ready to use.

## Mounting Secrets and Configuration Files

### Directory Layout on the Host

Organize your project with this structure:

```
my-project/
├─ clusterconfig/                # All cluster configuration
│  ├─ install-config.yaml       # OpenShift install configuration
│  ├─ pull-secret.json          # Red Hat pull secret
│  └─ ssh-private-key           # SSH private key for cluster access
└─ playbooks/                   # Ansible playbooks
   └─ openshift-install.yml     # OpenShift installation playbook
```

### Mounting with Podman

Mount your configuration and playbooks into the execution environment:

```bash
podman run --rm -it \
  -v $(pwd)/clusterconfig:/runner/project/clusterconfig:Z \
  -v $(pwd)/playbooks:/runner/project/playbooks:Z \
  -e KUBECONFIG=/runner/project/clusterconfig/auth/kubeconfig \
  my-ee-image:latest \
  ansible-playbook /runner/project/playbooks/openshift-install.yml
```

### Mount Options Explained

- **`-v $(pwd)/clusterconfig:/runner/project/clusterconfig:Z`**
  - Mounts your cluster configuration files
  - Includes install-config.yaml, pull-secret.json, and SSH keys
- **`-v $(pwd)/playbooks:/runner/project/playbooks:Z`**
  - Mounts your Ansible playbooks
- **`-e KUBECONFIG=/runner/project/clusterconfig/auth/kubeconfig`**
  - Sets the kubeconfig location for OpenShift CLI tools
- **SELinux `:Z`**: Keeps permissions correct on RHEL/Fedora/Podman hosts

### Configuration in install-config.yaml

Include secrets directly in your install configuration:

```yaml
apiVersion: v1
baseDomain: example.com
metadata:
  name: my-cluster
platform:
  vsphere:
    vcenter: vcenter.example.com
    username: admin@vsphere.local
    password: password
    datacenter: datacenter
    defaultDatastore: datastore
pullSecret: >
  {"auths":{"cloud.openshift.com":{"auth":"..."}}}
sshKey: |
  ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC... user@host
```

### Using ansible-navigator Configuration

Create an `ansible-navigator.yml` file for consistent execution:

```yaml
---
ansible-navigator:
  execution-environment:
    image: my-ee-image:latest
    volume-mounts:
      - src: ./clusterconfig
        dest: /runner/project/clusterconfig
        options: Z
      - src: ./playbooks
        dest: /runner/project/playbooks
        options: Z
    environment-variables:
      - KUBECONFIG: /runner/project/clusterconfig/auth/kubeconfig
```

Then run with:

```bash
ansible-navigator run playbooks/openshift-install.yml -m stdout
```

## Running Playbooks and Commands

### Interactive Development

Launch an interactive shell in the execution environment:

```bash
podman run --rm -it \
  -v $(pwd):/runner/project:Z \
  -e KUBECONFIG=/runner/project/clusterconfig/auth/kubeconfig \
  my-ee-image:latest \
  /bin/bash
```

Inside the container, you have access to all tools:

```bash
# Verify OpenShift tools
openshift-install version
oc version --client
kubectl version --client

# Run OpenShift commands
openshift-install create manifests --dir /runner/project/clusterconfig
openshift-install create cluster --dir /runner/project/clusterconfig
```

### Running Ansible Playbooks

#### Using ansible-navigator
```bash
ansible-navigator run playbooks/openshift-install.yml \
  --eei my-ee-image:latest \
  -m stdout
```

#### Using Podman directly
```bash
podman run --rm -it \
  -v $(pwd)/clusterconfig:/runner/project/clusterconfig:Z \
  -v $(pwd)/playbooks:/runner/project/playbooks:Z \
  -e KUBECONFIG=/runner/project/clusterconfig/auth/kubeconfig \
  my-ee-image:latest \
  ansible-playbook /runner/project/playbooks/openshift-install.yml \
  -e install_dir=/runner/project/clusterconfig
```

### Ansible Playbook Tasks

Use OpenShift tools in your playbooks:

```yaml
- name: Generate OpenShift manifests
  ansible.builtin.command:
    cmd: openshift-install create manifests --dir {{ install_dir }}
  vars:
    install_dir: /runner/project/clusterconfig

- name: Create OpenShift cluster
  ansible.builtin.command:
    cmd: openshift-install create cluster --dir {{ install_dir }}
  vars:
    install_dir: /runner/project/clusterconfig

- name: Wait for cluster to be ready
  ansible.builtin.command:
    cmd: oc get nodes
  environment:
    KUBECONFIG: "{{ install_dir }}/auth/kubeconfig"
```

## Security Considerations

### Sensitive Data Handling

- **Pull Secrets**: Store in encrypted files or Ansible Vault
- **SSH Keys**: Use proper file permissions (600) and SELinux context
- **Passwords**: Never store in plain text; use Ansible Vault or external secret management

### File Permissions

```bash
# Set proper permissions for sensitive files
chmod 600 clusterconfig/ssh-private-key
chmod 600 clusterconfig/pull-secret.json

# Fix SELinux context for mounted volumes
chcon -Rt svirt_sandbox_file_t clusterconfig/
chcon -Rt svirt_sandbox_file_t playbooks/
```

### Container Security

- **Minimal Privileges**: Use non-root users when possible
- **Ephemeral Containers**: Use `--rm` flag for temporary containers
- **Network Access**: Ensure container has access to required endpoints
- **Resource Limits**: Set appropriate CPU and memory limits

### Ansible Vault Integration

Encrypt sensitive data with Ansible Vault:

```bash
# Encrypt secrets
ansible-vault encrypt clusterconfig/pull-secret.json

# Use in playbooks
ansible-playbook playbook.yml --vault-password-file vault-password.txt
```

## Best Practices

### Execution Environment Design

1. **Single Purpose**: Design EEs for specific use cases
2. **Version Pinning**: Pin specific versions of tools and dependencies
3. **Size Optimization**: Remove unnecessary packages and files
4. **Security Updates**: Regularly update base images and dependencies

### File Organization

1. **Clear Structure**: Organize files logically
2. **Consistent Naming**: Use consistent naming conventions
3. **Documentation**: Document configuration and usage
4. **Version Control**: Track changes to configuration files

### Development Workflow

1. **Local Development**: Use interactive containers for development
2. **Testing**: Test in isolated environments
3. **CI/CD Integration**: Integrate with automated pipelines
4. **Monitoring**: Monitor execution and performance

### Performance Optimization

1. **Image Caching**: Use image caching for faster builds
2. **Layer Optimization**: Minimize layers and optimize build steps
3. **Resource Management**: Set appropriate resource limits
4. **Network Optimization**: Optimize network access patterns

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

#### Permission Issues
```bash
# Check SELinux context
ls -Z clusterconfig/

# Fix SELinux context
chcon -Rt svirt_sandbox_file_t clusterconfig/
```

#### Network Issues
```bash
# Test network connectivity
podman run --rm my-ee-image:latest curl -I https://mirror.openshift.com

# Check DNS resolution
podman run --rm my-ee-image:latest nslookup registry.redhat.io
```

#### Tool Verification
```bash
# Test OpenShift tools
podman run --rm my-ee-image:latest openshift-install version
podman run --rm my-ee-image:latest oc version --client
```

### Debug Commands

#### Container Debugging
```bash
# Interactive debugging
podman run --rm -it --entrypoint /bin/bash my-ee-image:latest

# Check file system
podman run --rm my-ee-image:latest ls -la /usr/local/bin/

# Check environment
podman run --rm my-ee-image:latest printenv | sort
```

#### Ansible Debugging
```bash
# Test Ansible connectivity
podman run --rm -it \
  -v $(pwd):/runner/project:Z \
  my-ee-image:latest \
  ansible all -m ping -i inventory

# Validate inventory
podman run --rm -it \
  -v $(pwd):/runner/project:Z \
  my-ee-image:latest \
  ansible-inventory -i inventory --list
```

### Getting Help

#### Tool Help
```bash
# Get help for each tool
ansible-builder --help
ansible-navigator --help
podman --help
openshift-install --help
```

#### Log Analysis
```bash
# Check build logs
cat builder.out

# Check container logs
podman logs <container_id>

# Check Ansible logs
tail -f /runner/project/ansible-logs/ansible.log
```

---

## Summary

This comprehensive guide covers:

1. **Understanding execution environments** as containerized automation platforms
2. **Building execution environments** with OpenShift tools pre-installed
3. **Mounting secrets and configuration files** securely into containers
4. **Running playbooks and commands** effectively
5. **Security considerations** for production use
6. **Best practices** for development and deployment
7. **Troubleshooting** common issues

By following this guide, you can create robust, secure, and efficient execution environments for OpenShift cluster management and automation.

---

## Support and Resources

### Official Documentation
- [Ansible Builder Documentation](https://ansible.readthedocs.io/projects/builder/)
- [Ansible Navigator Documentation](https://ansible.readthedocs.io/projects/navigator/)
- [OpenShift Documentation](https://docs.openshift.com/)
- [Podman Documentation](https://docs.podman.io/)

### Project Maintenance
- **Maintainer**: ODFL Platform Team
- **Last Updated**: December 2024
- **Version**: 1.0.0
- **License**: Internal Use Only