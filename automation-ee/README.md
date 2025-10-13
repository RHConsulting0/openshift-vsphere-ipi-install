# OpenShift vSphere IPI Automation Execution Environment

A comprehensive containerized execution environment for OpenShift cluster installation, management, and day-2 operations on VMware vSphere using Installer-Provisioned Infrastructure (IPI).

## 📋 Table of Contents

- [Overview](#-overview)
- [Quick Start](#-quick-start)
- [Project Structure](#-project-structure)
- [Execution Environment](#-execution-environment)
- [Prerequisites](#-prerequisites)
- [Building the Execution Environment](#-building-the-execution-environment)
- [Usage Examples](#-usage-examples)
- [Configuration](#-configuration)
- [Day-2 Operations](#-day-2-operations)
- [Troubleshooting](#-troubleshooting)
- [Documentation](#-documentation)
- [Contributing](#-contributing)
- [License](#-license)

## 🎯 Overview

The OpenShift vSphere IPI Automation Execution Environment provides a complete, containerized solution for deploying and managing OpenShift Container Platform clusters on VMware vSphere infrastructure. This enterprise-grade solution leverages Ansible automation with containerized execution environments to ensure consistent, repeatable, and secure deployments.

### **Key Features**

- **🚀 Containerized Execution**: Consistent tooling across all environments
- **🔧 Ansible Automation**: Comprehensive playbooks for cluster lifecycle management
- **📦 Helm Integration**: Package management for applications and configurations
- **🔐 Security-First**: Encrypted secrets management and secure configurations
- **📊 Monitoring**: Built-in monitoring and validation capabilities
- **🔄 GitOps Ready**: Integration with ArgoCD and Advanced Cluster Management
- **📚 Comprehensive Documentation**: Complete guides and troubleshooting

### **Supported Operations**

- **Cluster Installation**: Automated OpenShift cluster deployment
- **Configuration Management**: Day-2 operations and cluster customization
- **Secret Management**: Secure handling of sensitive data
- **Monitoring & Validation**: Health checks and compliance validation
- **GitOps Integration**: Automated configuration deployment
- **Disaster Recovery**: Backup and recovery procedures

## 🚀 Quick Start

### **Prerequisites**

- **Container Runtime**: Podman 4.0+ or Docker 20.10+
- **OpenShift Access**: Red Hat OpenShift pull secret
- **vSphere Environment**: VMware vSphere 7.0+ with appropriate permissions
- **Network Access**: DNS resolution and load balancer configuration
- **SSH Keys**: Key pair for cluster access

### **5-Minute Setup**

```bash
# 1. Clone the repository
git clone <repository-url>
cd openshift-vsphere-ipi-install/automation-ee

# 2. Install prerequisites
cd prep
./install-ansible-tools.sh

# 3. Build execution environment
cd ../ocp-provision-ee
./builder.sh

# 4. Verify installation
podman images | grep ocp-provision-ee
```

### **Quick Deployment**

```bash
# Deploy a complete OpenShift cluster
cd ../
./010-run-prep-cluster-install.sh lab lab
./030-run-install-and-monitor.sh lab lab
./040-run-install-gitops.sh lab lab
```

## 📁 Project Structure

```
automation-ee/
├── README.md                           # This file - Main documentation
├── README-execution-environment-guide.md  # Complete EE guide
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
└── ocp-provision-ee.tgz               # Packaged execution environment
```

## 🐳 Execution Environment

### **Base Image**

- **Registry**: `registry.redhat.io/ansible-automation-platform-25/ee-supported-rhel9:latest`
- **OS**: Red Hat Enterprise Linux 9
- **Architecture**: x86_64
- **Size**: ~2.5GB (compressed)

### **Included Tools**

| Tool | Version | Purpose |
|------|---------|---------|
| **Ansible Core** | 2.15+ | Automation engine |
| **OpenShift CLI** | 4.15+ | Cluster management |
| **kubectl** | 1.28+ | Kubernetes management |
| **Helm** | 3.16.3 | Package management |
| **Kustomize** | 5.5.0 | Configuration management |
| **Policy Generator** | 1.15.0 | ACM policy generation |
| **Python** | 3.11 | Runtime environment |
| **Git** | 2.39+ | Version control |

### **Ansible Collections**

- **kubernetes.core**: Kubernetes/OpenShift management
- **community.hashi_vault**: HashiCorp Vault integration
- **community.general**: General purpose modules
- **ansible.scm**: Source control management
- **redhat.openshift**: OpenShift-specific modules

## ⚙️ Prerequisites

### **System Requirements**

- **CPU**: 4+ cores recommended
- **Memory**: 8GB+ RAM
- **Storage**: 20GB+ free space
- **Network**: Internet access for image pulls

### **Software Dependencies**

```bash
# Required packages
sudo dnf install -y podman git ansible-core

# Or with Docker
sudo dnf install -y docker git ansible-core
sudo systemctl enable --now docker
```

### **vSphere Requirements**

- **vCenter**: 7.0+ with appropriate permissions
- **ESXi**: 7.0+ hosts
- **Network**: DNS resolution and load balancer
- **Storage**: Datastore with sufficient capacity
- **Resource Pool**: CPU and memory allocation

## 🔨 Building the Execution Environment

### **Automated Build**

```bash
# Build with default configuration
cd ocp-provision-ee
./builder.sh

# Build with verbose output
./builder.sh --verbose

# Clean build (remove existing image)
./builder.sh --clean
```

### **Manual Build**

```bash
# Build using ansible-builder
ansible-builder build --tag ocp-provision-ee:latest

# Build with custom configuration
ansible-builder build \
  --build-arg ANSIBLE_GALAXY_CLI_COLLECTION_OPTS="--upgrade" \
  --tag ocp-provision-ee:latest
```

### **Build Configuration**

The execution environment is defined in `execution-environment.yaml`:

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

## 📚 Usage Examples

### **1. Cluster Installation**

```bash
# Prepare cluster environment
./010-run-prep-cluster-install.sh lab lab

# Install and monitor cluster
./030-run-install-and-monitor.sh lab lab

# Install GitOps operator
./040-run-install-gitops.sh lab lab
```

### **2. Using Execution Environment Directly**

```bash
# Run Ansible playbook
podman run --rm -it \
  -v $(pwd)/clusterconfig:/runner/project/clusterconfig:Z \
  -v $(pwd)/playbooks:/runner/project/playbooks:Z \
  -e KUBECONFIG=/runner/project/clusterconfig/auth/kubeconfig \
  ocp-provision-ee:latest \
  ansible-playbook /runner/project/playbooks/openshift-install.yml

# Run OpenShift CLI commands
podman run --rm -it \
  -v $(pwd)/clusterconfig:/runner/project/clusterconfig:Z \
  -e KUBECONFIG=/runner/project/clusterconfig/auth/kubeconfig \
  ocp-provision-ee:latest \
  oc get nodes
```

### **3. Helm Operations**

```bash
# Install Helm chart
podman run --rm -it \
  -v $(pwd)/charts:/runner/project/charts:Z \
  ocp-provision-ee:latest \
  helm install my-app ./charts/my-app

# List Helm releases
podman run --rm -it \
  -e KUBECONFIG=/runner/project/clusterconfig/auth/kubeconfig \
  ocp-provision-ee:latest \
  helm list
```

### **4. Kustomize Operations**

```bash
# Build Kustomize configuration
podman run --rm -it \
  -v $(pwd)/kustomize:/runner/project/kustomize:Z \
  ocp-provision-ee:latest \
  kustomize build kustomize/overlays/production

# Apply Kustomize configuration
podman run --rm -it \
  -v $(pwd)/kustomize:/runner/project/kustomize:Z \
  -e KUBECONFIG=/runner/project/clusterconfig/auth/kubeconfig \
  ocp-provision-ee:latest \
  kustomize build kustomize/overlays/production | oc apply -f -
```

## ⚙️ Configuration

### **Environment-Specific Configurations**

The execution environment supports multiple configuration profiles:

- **`execution-environment.yaml`**: Default configuration
- **`execution-environment-customer.yaml`**: Customer-specific settings
- **`execution-environment-odfl.yaml`**: ODFL-specific configuration
- **`execution-environment-redhat.yaml`**: Red Hat-specific configuration

### **Ansible Configuration**

Configuration files are located in the `files/` directory:

- **`ansible.cfg`**: Default Ansible configuration
- **`ansible-customer.cfg`**: Customer-specific Ansible settings

### **Customization**

```bash
# Create custom configuration
cp execution-environment.yaml execution-environment-custom.yaml

# Edit configuration
vim execution-environment-custom.yaml

# Build with custom configuration
ansible-builder build -f execution-environment-custom.yaml --tag ocp-provision-ee:custom
```

## 🔄 Day-2 Operations

### **GitOps Integration**

The execution environment includes comprehensive GitOps capabilities:

- **ArgoCD Integration**: Automated application deployment
- **Advanced Cluster Management**: Multi-cluster management
- **Policy Management**: Automated policy enforcement
- **Configuration Drift**: Detection and remediation

### **Monitoring and Validation**

- **Cluster Health**: Automated health checks
- **Compliance Validation**: Security and policy compliance
- **Performance Monitoring**: Resource utilization tracking
- **Alert Management**: Automated alerting and notification

### **Backup and Recovery**

- **Configuration Backup**: Automated backup of cluster configurations
- **Disaster Recovery**: Automated recovery procedures
- **Data Protection**: Secure backup and restore capabilities

## 🚨 Troubleshooting

### **Common Issues**

#### **Build Failures**
```bash
# Check build logs
cat ocp-provision-ee/builder.out

# Clean and rebuild
./clean-build-env.sh
./builder.sh --clean
```

#### **Container Issues**
```bash
# Check container logs
podman logs <container-id>

# Verify image exists
podman images | grep ocp-provision-ee

# Test container execution
podman run --rm ocp-provision-ee:latest ansible --version
```

#### **Permission Issues**
```bash
# Fix SELinux contexts
sudo setsebool -P container_manage_cgroup on

# Fix file permissions
chmod +x *.sh
```

### **Debug Mode**

```bash
# Enable verbose output
export ANSIBLE_VERBOSITY=4

# Run with debug logging
podman run --rm -it \
  -e ANSIBLE_VERBOSITY=4 \
  ocp-provision-ee:latest \
  ansible-playbook playbook.yml
```

### **Performance Optimization**

```bash
# Use parallel execution
ansible-playbook playbook.yml -f 10

# Optimize container resources
podman run --rm -it \
  --memory=4g \
  --cpus=2 \
  ocp-provision-ee:latest \
  ansible-playbook playbook.yml
```

## 📚 Documentation

### **Complete Guides**

- **`README-execution-environment-guide.md`**: Comprehensive execution environment guide
- **`ocp-provision-ee/README.md`**: Execution environment specific documentation
- **`prep/README.md`**: Prerequisites and setup guide

### **Additional Resources**

- **Project Documentation**: `../DOCUMENTATION.md`
- **User Guide**: `../USER-GUIDE-SUMMARY.md`
- **Technical Summary**: `../TECHNICAL-SUMMARY.md`
- **Executive Summary**: `../EXECUTIVE-SUMMARY.md`

### **Quick Reference**

| Command | Purpose |
|---------|---------|
| `./builder.sh` | Build execution environment |
| `./clean-build-env.sh` | Clean build environment |
| `podman images` | List container images |
| `ansible-playbook --version` | Check Ansible version |
| `oc version` | Check OpenShift CLI version |

## 🤝 Contributing

### **Development Workflow**

1. **Fork Repository**: Create a fork of the repository
2. **Create Branch**: Create a feature branch
3. **Make Changes**: Implement your changes
4. **Test Changes**: Run tests and validation
5. **Submit PR**: Create a pull request

### **Code Standards**

- **Documentation**: Update README files for new features
- **Testing**: Include tests for new functionality
- **Versioning**: Follow semantic versioning
- **Security**: Follow security best practices

### **Testing**

```bash
# Run validation tests
ansible-playbook tests/validate-execution-environment.yml

# Test container functionality
podman run --rm ocp-provision-ee:latest ansible-playbook tests/test-playbook.yml
```

## 📄 License

This project is part of the ODFL OpenShift vSphere IPI Installation automation framework.

---

**Note**: This execution environment is designed for production use and includes comprehensive security, monitoring, and troubleshooting capabilities. Always test changes in a development environment before deploying to production.