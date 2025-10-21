# Managed Clusters Lab Manifests

This directory contains manifests for deploying and managing the LAB cluster as a managed cluster in the hub cluster.

## 📋 Table of Contents

- [Overview](#-overview)
- [Directory Structure](#-directory-structure)
- [Manifest Components](#-manifest-components)
- [Configuration](#️-configuration)
- [Usage Examples](#-usage-examples)
- [Troubleshooting](#-troubleshooting)
- [Contributing](#-contributing)
- [License](#-license)

## 🎯 Overview

The managed clusters lab manifests provide:

- **Cluster Registration**: Registers the LAB cluster with the hub
- **GitOps Configuration**: Configures GitOps for the LAB cluster
- **Policy Management**: Applies policies to the LAB cluster
- **Resource Management**: Manages LAB cluster resources

## 📁 Directory Structure

```
manifests/
├── README.md                           # This file
└── cluster-gitops-repository-configuration/  # GitOps repository configuration
    └── kustomization.yaml              # Kustomization for GitOps config
```

## 🔧 Manifest Components

### 1. GitOps Repository Configuration

**Purpose**: Configures GitOps repository settings for the LAB cluster management

**Configuration:**
```yaml
# cluster-gitops-repository-configuration/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

# Applied to acm-policies-openshift-gitops namespace for cluster management lookup
namespace: acm-policies-openshift-gitops

resources:
- ../../../../../../capabilities/kustomize/bases/cluster-gitops-repository-configuration

patches:
# Customize ConfigMap name for labhub cluster
- target:
    name: cluster-gitops-repo-config
  patch: |-
    - op: replace
      path: /metadata/name
      value: labhub-gitops-repo-config
# Set GitOps repository URL
- target:
    name: cluster-gitops-repo-config
  patch: |-
    - op: replace
      path: /data/gitopsRepository
      value: https://github.com/RHConsulting0/openshift-vsphere-ipi-install.git
# Set GitOps revision/branch
- target:
    name: cluster-gitops-repo-config
  patch: |-
    - op: replace
      path: /data/gitopsRevision
      value: automation
```

**Key Features:**
- **Chicken/Egg Solution**: Solves initialization problem when setting up new clusters
- **Cluster Management Integration**: Applied to `acm-policies-openshift-gitops` namespace
- **Base Configuration Reuse**: Leverages shared base configuration from capabilities
- **Cluster-Specific Customization**: Patches base configuration for labhub cluster

## ⚙️ Configuration

### Cluster Labels

Consistent labeling for cluster identification:

```yaml
labels:
  cluster-type: "workload"
  environment: "lab"
  cluster-name: "lab"
  managed-by: "hub-cluster"
```

### GitOps Settings

The GitOps configuration is managed through a ConfigMap in the `acm-policies-openshift-gitops` namespace:

```yaml
# ConfigMap: labhub-gitops-repo-config
apiVersion: v1
kind: ConfigMap
metadata:
  name: labhub-gitops-repo-config
  namespace: acm-policies-openshift-gitops
data:
  gitopsRepository: "https://github.com/RHConsulting0/openshift-vsphere-ipi-install.git"
  gitopsRevision: "automation"
immutable: false
```

**Configuration Details:**
- **Repository**: `https://github.com/RHConsulting0/openshift-vsphere-ipi-install.git`
- **Branch**: `automation`
- **Namespace**: `acm-policies-openshift-gitops`
- **ConfigMap Name**: `labhub-gitops-repo-config`

### Cluster Management Integration

The managed cluster configuration integrates with the cluster management system:

```yaml
# Kustomization configuration
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: acm-policies-openshift-gitops

resources:
- ../../../../../../capabilities/kustomize/bases/cluster-gitops-repository-configuration

patches:
- target:
    name: cluster-gitops-repo-config
  patch: |-
    - op: replace
      path: /metadata/name
      value: labhub-gitops-repo-config
- target:
    name: cluster-gitops-repo-config
  patch: |-
    - op: replace
      path: /data/gitopsRepository
      value: https://github.com/RHConsulting0/openshift-vsphere-ipi-install.git
- target:
    name: cluster-gitops-repo-config
  patch: |-
    - op: replace
      path: /data/gitopsRevision
      value: automation
```

**Integration Details:**
- **Base Configuration**: Uses shared base configuration from `capabilities/kustomize/bases/`
- **Namespace**: Applied to `acm-policies-openshift-gitops` for cluster management lookup
- **Patches**: Customizes the base configuration for the labhub cluster
- **Chicken/Egg Solution**: Solves initialization problem for new clusters

## 🚀 Usage Examples

### 1. Deploy GitOps Repository Configuration

```bash
# Deploy GitOps configuration
kustomize build cluster-gitops-repository-configuration/ | oc apply -f -

# Verify deployment
oc get configmap labhub-gitops-repo-config -n acm-policies-openshift-gitops
```

### 2. Verify Configuration

```bash
# Check ConfigMap exists
oc get configmap labhub-gitops-repo-config -n acm-policies-openshift-gitops

# Verify configuration data
oc get configmap labhub-gitops-repo-config -n acm-policies-openshift-gitops -o yaml

# Check namespace
oc get all -n acm-policies-openshift-gitops
```

### 3. Test Configuration Build

```bash
# Test Kustomize build
kustomize build cluster-gitops-repository-configuration/

# Test with dry-run
kustomize build cluster-gitops-repository-configuration/ | oc apply --dry-run=client -f -
```

## 🚨 Troubleshooting

### Common Issues

1. **Cluster Registration Failed**
   ```bash
   # Check managed cluster status
   oc get managedcluster lab
   
   # Check cluster details
   oc describe managedcluster lab
   
   # Check cluster conditions
   oc get managedcluster lab -o jsonpath='{.status.conditions[*].message}'
   ```

2. **GitOps Configuration Issues**
   ```bash
   # Check configmap
   oc get configmap labhub-gitops-repo-config -n acm-policies-openshift-gitops
   
   # Check configmap data
   oc get configmap labhub-gitops-repo-config -n acm-policies-openshift-gitops -o yaml
   
   # Check GitOps operator
   oc get pods -n openshift-gitops
   
   # Check cluster management namespace
   oc get all -n acm-policies-openshift-gitops
   ```

3. **Policy Placement Issues**
   ```bash
   # Check placement rule
   oc get placementrule lab-placement -n open-cluster-management
   
   # Check cluster labels
   oc get managedcluster lab -o yaml | grep -A 5 -B 5 "labels"
   
   # Check placement rule details
   oc describe placementrule lab-placement -n open-cluster-management
   ```

4. **Resource Quota Issues**
   ```bash
   # Check resource quota
   oc get resourcequota lab-resource-quota -n open-cluster-management
   
   # Check quota usage
   oc describe resourcequota lab-resource-quota -n open-cluster-management
   
   # Check quota limits
   oc get resourcequota lab-resource-quota -n open-cluster-management -o yaml
   ```

### Debug Mode

Enable debug mode for detailed troubleshooting:

```bash
# Kustomize debug
kustomize build clusters/labhub/capabilities/managed-clusters/lab/manifests/ --enable-helm --enable-alpha-plugins

# Cluster debug
oc get managedcluster lab -o yaml | grep -A 10 -B 10 "status"

# Policy debug
oc get placementrule lab-placement -n open-cluster-management -o yaml
```

### Log Analysis

```bash
# Check cluster registration logs
oc logs -n open-cluster-management deployment/cluster-registration-controller

# Check GitOps logs
oc logs -n openshift-gitops deployment/argocd-application-controller

# Check policy logs
oc logs -n open-cluster-management deployment/governance-policy-framework
```

## 🤝 Contributing

### Development Workflow

1. **Create Feature Branch**:
   ```bash
   git checkout -b feature/managed-clusters-lab-update
   ```

2. **Make Changes**:
   - Update cluster manifests
   - Modify GitOps configuration
   - Update documentation

3. **Test Changes**:
   ```bash
   # Test manifest build
   kustomize build clusters/labhub/capabilities/managed-clusters/lab/manifests/
   
   # Test with deployment
   oc apply -f clusters/labhub/capabilities/managed-clusters/lab/manifests/
   ```

4. **Create Pull Request**:
   - Include description of changes
   - Reference any related issues
   - Ensure all tests pass

### Code Standards

- **Consistent Structure**: Follow established directory structure
- **Documentation**: Include README.md for new components
- **Testing**: Add tests for new functionality
- **Naming**: Use descriptive, consistent naming conventions

## 📄 License

This project is part of the ODFL OpenShift vSphere IPI Installation automation framework.

---

**Note**: Always test managed cluster changes in a development environment before deploying to production. Consider the impact of changes on cluster management and policy enforcement.