# OpenShift Install Directory

This directory serves as the working directory for OpenShift installer operations and contains all generated artifacts, manifests, and configuration files for cluster deployment.

## 📋 Table of Contents

- [Overview](#-overview)
- [Directory Structure](#-directory-structure)
- [Configuration Files](#️-configuration-files)
- [Generated Manifests](#-generated-manifests)
- [Workflow](#-workflow)
- [Validation](#-validation)
- [Security](#-security)
- [Troubleshooting](#-troubleshooting)
- [Best Practices](#-best-practices)
- [References](#-references)

## 🎯 Overview

The `install-dir` directory is the target working directory used by the OpenShift installer (`openshift-install --dir=<install-dir> ...`). It serves as:

- **Configuration Repository**: Holds the cluster's `install-config.yaml` and generated artifacts
- **Manifest Storage**: Contains all generated Kubernetes/OpenShift manifests
- **Authentication Artifacts**: Stores credentials and bootstrap auth artifacts
- **Metadata Repository**: Contains installer metadata and cluster information
- **Working Directory**: Central location for all installer operations

## 📁 Directory Structure

```
install-dir/
├── README.md                           # This file - Documentation
├── install-config.yaml                 # Active cluster configuration
├── cluster-api/                        # Cluster API manifests
│   ├── 000_capi-namespace.yaml        # Cluster API namespace
│   ├── 01_capi-cluster-0.yaml         # Cluster API cluster definition
│   ├── 01_vsphere-cluster-0.yaml      # vSphere cluster configuration
│   └── 01_vsphere-creds-0.yaml        # vSphere credentials
├── manifests/                          # OpenShift cluster manifests
│   ├── cloud-provider-config.yaml     # Cloud provider configuration
│   ├── cluster-config.yaml            # Cluster configuration
│   ├── cluster-dns-02-config.yml      # DNS configuration
│   ├── cluster-infrastructure-02-config.yml  # Infrastructure config
│   ├── cluster-ingress-02-config.yml  # Ingress configuration
│   ├── cluster-network-02-config.yml  # Network configuration
│   ├── cluster-proxy-01-config.yaml   # Proxy configuration
│   ├── cluster-scheduler-02-config.yml  # Scheduler configuration
│   ├── cvo-overrides.yaml             # Cluster Version Operator overrides
│   ├── kube-cloud-config.yaml         # Kubernetes cloud configuration
│   ├── kube-system-configmap-root-ca.yaml  # Root CA configuration
│   ├── machine-config-server-tls-secret.yaml  # Machine config server TLS
│   ├── openshift-config-secret-pull-secret.yaml  # Pull secret configuration
│   └── user-ca-bundle-config.yaml     # User CA bundle configuration
└── openshift/                          # OpenShift-specific configurations
    ├── 99_cloud-creds-secret.yaml     # Cloud credentials secret
    ├── 99_feature-gate.yaml           # Feature gate configuration
    ├── 99_kubeadmin-password-secret.yaml  # kubeadmin password secret
    ├── 99_openshift-cluster-api_master-machines-0.yaml  # Master machine 0
    ├── 99_openshift-cluster-api_master-machines-1.yaml  # Master machine 1
    ├── 99_openshift-cluster-api_master-machines-2.yaml  # Master machine 2
    ├── 99_openshift-cluster-api_master-user-data-secret.yaml  # Master user data
    ├── 99_openshift-cluster-api_worker-machineset-0.yaml  # Worker machine set
    ├── 99_openshift-cluster-api_worker-user-data-secret.yaml  # Worker user data
    ├── 99_openshift-machine-api_master-control-plane-machine-set.yaml  # Control plane machine set
    ├── 99_openshift-machineconfig_99-master-ssh.yaml  # Master SSH configuration
    ├── 99_openshift-machineconfig_99-worker-ssh.yaml  # Worker SSH configuration
    ├── 99_role-cloud-creds-secret-reader.yaml  # Cloud credentials reader role
    └── openshift-install-manifests.yaml  # OpenShift install manifests
```

## ⚙️ Configuration Files

### **Install Configuration (`install-config.yaml`)**

The primary configuration file that defines the cluster setup:

```yaml
apiVersion: v1
baseDomain: example.com
metadata:
  name: test-cluster
platform:
  vsphere:
    vcenter: vcenter.example.com
    username: admin@vsphere.local
    password: password
    datacenter: datacenter
    defaultDatastore: datastore
    cluster: cluster
    network: network
    diskType: thin
    folder: /datacenter/vm/folder
    resourcePool: /datacenter/host/cluster/Resources
    apiVIP: 192.168.1.10
    ingressVIP: 192.168.1.11
    dnsVIP: 192.168.1.12
    defaultMachinePlatform:
      diskSizeGB: 120
      memoryMB: 16384
      numCPUs: 4
      osDisk:
        diskSizeGB: 120
pullSecret: '{"auths":{"registry.redhat.io":{"auth":"..."}}}'
sshKey: ssh-rsa AAAAB3NzaC1yc2E...
```

**Key Configuration Sections:**
- **Platform**: vSphere configuration and credentials
- **Networking**: VIP addresses and network settings
- **Compute**: Machine specifications and sizing
- **Authentication**: Pull secrets and SSH keys
- **Domain**: Base domain and cluster naming

## 📄 Generated Manifests

### **Cluster API Manifests (`cluster-api/`)**

Manifests for Cluster API (CAPI) integration:

#### **`000_capi-namespace.yaml`**
- Creates the `cluster-api` namespace
- Required for Cluster API resources

#### **`01_capi-cluster-0.yaml`**
- Defines the Cluster API cluster resource
- Links to vSphere cluster configuration

#### **`01_vsphere-cluster-0.yaml`**
- vSphere-specific cluster configuration
- Defines vSphere cluster properties

#### **`01_vsphere-creds-0.yaml`**
- vSphere credentials secret
- Contains vCenter authentication information

### **OpenShift Manifests (`manifests/`)**

Core OpenShift cluster configuration manifests:

#### **Cloud Provider Configuration**
- **`cloud-provider-config.yaml`**: vSphere cloud provider settings
- **`kube-cloud-config.yaml`**: Kubernetes cloud configuration

#### **Cluster Configuration**
- **`cluster-config.yaml`**: General cluster settings
- **`cluster-dns-02-config.yml`**: DNS configuration
- **`cluster-infrastructure-02-config.yml`**: Infrastructure settings
- **`cluster-ingress-02-config.yml`**: Ingress controller configuration
- **`cluster-network-02-config.yml`**: Network configuration
- **`cluster-proxy-01-config.yaml`**: Proxy settings
- **`cluster-scheduler-02-config.yml`**: Scheduler configuration

#### **Security and Authentication**
- **`kube-system-configmap-root-ca.yaml`**: Root CA configuration
- **`machine-config-server-tls-secret.yaml`**: Machine config server TLS
- **`openshift-config-secret-pull-secret.yaml`**: Container registry pull secret
- **`user-ca-bundle-config.yaml`**: User CA bundle configuration

#### **Operator Configuration**
- **`cvo-overrides.yaml`**: Cluster Version Operator overrides

### **OpenShift-Specific Configs (`openshift/`)**

OpenShift-specific configurations and machine definitions:

#### **Authentication and Security**
- **`99_cloud-creds-secret.yaml`**: Cloud credentials secret
- **`99_kubeadmin-password-secret.yaml`**: kubeadmin password
- **`99_role-cloud-creds-secret-reader.yaml`**: Cloud credentials reader role

#### **Feature Configuration**
- **`99_feature-gate.yaml`**: Feature gate settings

#### **Machine Definitions**
- **`99_openshift-cluster-api_master-machines-*.yaml`**: Master node definitions
- **`99_openshift-cluster-api_worker-machineset-0.yaml`**: Worker node machine set
- **`99_openshift-machine-api_master-control-plane-machine-set.yaml`**: Control plane machine set

#### **User Data and Configuration**
- **`99_openshift-cluster-api_master-user-data-secret.yaml`**: Master node user data
- **`99_openshift-cluster-api_worker-user-data-secret.yaml`**: Worker node user data

#### **Machine Configuration**
- **`99_openshift-machineconfig_99-master-ssh.yaml`**: Master SSH configuration
- **`99_openshift-machineconfig_99-worker-ssh.yaml`**: Worker SSH configuration

#### **Installation Manifests**
- **`openshift-install-manifests.yaml`**: OpenShift installation manifests

## 🔄 Workflow

### **1. Prepare Configuration**

```bash
# Copy template configuration
cp ../templates/install-config.yaml.j2 ./install-config.yaml

# Edit configuration as needed
vim install-config.yaml
```

### **2. Generate Manifests**

```bash
# Generate all manifests
openshift-install create manifests --dir=./install-dir

# Verify generated manifests
ls -la manifests/ openshift/ cluster-api/
```

### **3. Review and Customize (Optional)**

```bash
# Review generated manifests
cat manifests/cluster-config.yaml
cat openshift/99_feature-gate.yaml

# Apply custom patches if needed
kubectl patch --local -f manifests/cluster-config.yaml -p '{"spec":{"additionalTrustBundle":"..."}}' -o yaml > manifests/cluster-config-patched.yaml
```

### **4. Generate Ignition Configs (Optional)**

```bash
# Generate ignition configs for manual provisioning
openshift-install create ignition-configs --dir=./install-dir

# Verify ignition configs
ls -la *.ign
```

### **5. Create Cluster (IPI Flow)**

```bash
# Create the cluster (provisions infrastructure)
openshift-install create cluster --dir=./install-dir

# Monitor installation
openshift-install wait-for install-complete --dir=./install-dir
```

### **6. Post-Installation**

```bash
# Export kubeconfig
export KUBECONFIG=./auth/kubeconfig

# Verify cluster access
oc get nodes
oc get clusteroperators

# Check installation status
oc get clusterversion
```

## ✅ Validation

### **YAML Validation**

```bash
# Validate YAML syntax
yamllint manifests/
yamllint openshift/
yamllint cluster-api/

# Check for common YAML issues
find . -name "*.yaml" -o -name "*.yml" | xargs yamllint
```

### **Kubernetes Resource Validation**

```bash
# Validate Kubernetes resources
kubeval --exit-status manifests/*.yaml
kubeval --exit-status openshift/*.yaml
kubeval --exit-status cluster-api/*.yaml

# Check resource definitions
oc apply --dry-run=client -f manifests/
oc apply --dry-run=client -f openshift/
oc apply --dry-run=client -f cluster-api/
```

### **Configuration Validation**

```bash
# Validate install configuration
openshift-install validate install-config --dir=./install-dir

# Check for required fields
grep -E "(baseDomain|metadata|platform)" install-config.yaml
```

### **Manifest Completeness**

```bash
# Check for required manifests
ls -la manifests/cluster-config.yaml
ls -la manifests/cloud-provider-config.yaml
ls -la openshift/99_openshift-cluster-api_master-machines-0.yaml
ls -la cluster-api/01_capi-cluster-0.yaml
```

## 🔒 Security

### **Sensitive Data Handling**

- **Pull Secrets**: Never commit pull secrets to public repositories
- **Passwords**: Store vSphere passwords securely
- **SSH Keys**: Protect private SSH keys
- **Certificates**: Keep TLS certificates secure

### **Best Practices**

```bash
# Redact sensitive data for version control
sed 's/password: .*/password: REDACTED/' install-config.yaml > install-config-redacted.yaml

# Use environment variables for sensitive data
export VSPHERE_PASSWORD="$(cat ~/.vsphere-password)"
```

### **File Permissions**

```bash
# Set appropriate permissions
chmod 600 install-config.yaml
chmod 600 auth/kubeconfig
chmod 600 auth/kubeadmin-password
```

## 🚨 Troubleshooting

### **Common Issues**

#### **Missing Manifests**
```bash
# Check if manifests were generated
ls -la manifests/ openshift/ cluster-api/

# Regenerate if missing
openshift-install create manifests --dir=./install-dir
```

#### **Invalid Configuration**
```bash
# Validate configuration
openshift-install validate install-config --dir=./install-dir

# Check for syntax errors
yamllint install-config.yaml
```

#### **Permission Issues**
```bash
# Check file permissions
ls -la install-config.yaml
ls -la auth/

# Fix permissions if needed
chmod 600 install-config.yaml
chmod 600 auth/*
```

### **Debug Commands**

```bash
# Check installer logs
openshift-install --log-level=debug create manifests --dir=./install-dir

# Verify generated resources
oc get -f manifests/ --dry-run=client
oc get -f openshift/ --dry-run=client
```

## 💡 Best Practices

### **Configuration Management**

1. **Keep Original Config**: Always keep a copy of the original `install-config.yaml`
2. **Version Control**: Commit redacted configurations to version control
3. **Document Changes**: Document any manifest customizations
4. **Test Changes**: Test configuration changes in non-production environments

### **Manifest Management**

1. **Review Generated Manifests**: Always review generated manifests before deployment
2. **Document Overrides**: Document any manifest overrides and their purpose
3. **Keep Patches**: Store manifest patches in version control
4. **Validate Changes**: Validate all changes before applying

### **Security Practices**

1. **Redact Sensitive Data**: Remove sensitive data before committing
2. **Use Secrets Management**: Use proper secrets management for sensitive data
3. **Rotate Credentials**: Regularly rotate passwords and keys
4. **Monitor Access**: Monitor access to sensitive files

### **Workflow Optimization**

1. **Use Templates**: Create templates for common configurations
2. **Automate Validation**: Automate validation in CI/CD pipelines
3. **Document Processes**: Document all processes and procedures
4. **Regular Updates**: Keep configurations up to date

## 📚 References

- [OpenShift Documentation: Creating a Cluster](https://docs.openshift.com/container-platform/latest/installing/index.html)
- [OpenShift Installer GitHub](https://github.com/openshift/installer)
- [Cluster API Documentation](https://cluster-api.sigs.k8s.io/)
- [vSphere Cloud Provider](https://github.com/kubernetes/cloud-provider-vsphere)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [YAML Lint Documentation](https://yamllint.readthedocs.io/)
- [Kubeval Documentation](https://www.kubeval.com/)

---

**Note**: This directory contains sensitive configuration data. Always follow security best practices and never commit sensitive information to public repositories.