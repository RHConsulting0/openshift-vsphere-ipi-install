# Development Protected Capabilities

This directory manages protected capabilities for development clusters, including storage management and other critical development assets.

## 📋 Table of Contents

- [Overview](#-overview)
- [Directory Structure](#-directory-structure)
- [Protected Capabilities](#%EF%B8%8F-protected-capabilities)
- [Configuration Management](#️-configuration-management)
- [Usage Examples](#-usage-examples)
- [Troubleshooting](#-troubleshooting)
- [Contributing](#-contributing)
- [License](#-license)

## 🎯 Overview

The development protected capabilities directory provides:

- **Storage Management**: Protected storage configurations for development
- **Development Tools**: Essential development and testing tools
- **Resource Protection**: Prevents accidental deletion of critical resources
- **Environment Isolation**: Development-specific configurations

**Note**: There is no `kustomization.yaml` at this level because these capabilities are meant to be loaded by an ArgoCD ApplicationSet.

## 📁 Directory Structure

```
dev-protected/
├── README.md                           # This file
└── capabilities/
    └── storage/                        # Storage management
        ├── kustomization.yaml
        ├── storage-class.yaml
        └── persistent-volume.yaml
```

## 🛡️ Protected Capabilities

### 1. Storage Management

**Purpose**: Protected storage configurations for development clusters

**Protection Level**: Medium - Protects development resources

**Features:**
- Storage class configuration
- Persistent volume management
- Storage quotas and limits
- Backup and recovery policies

**Configuration:**
```yaml
# storage/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- storage-class.yaml
- persistent-volume.yaml

labels:
- includeSelectors: false
  pairs:
    app.kubernetes.io/part-of: platform-management
    protection-level: medium
    component: storage
    environment: development
```

### 2. Future Capabilities

**Planned Capabilities:**
- Development tools and utilities
- Testing frameworks
- Debug utilities
- Development-specific monitoring

## ⚙️ Configuration Management

### ApplicationSet Integration

These capabilities are deployed via ArgoCD ApplicationSets with protection:

```yaml
# Example ApplicationSet configuration
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: dev-protected-capabilities
  annotations:
    argocd.argoproj.io/sync-wave: "2"
    argocd.argoproj.io/sync-options: "Prune=false"
spec:
  generators:
  - clusters:
      selector:
        matchLabels:
          cluster-type: "development"
          environment: "dev"
  template:
    metadata:
      name: "{{name}}-dev-protected"
      annotations:
        argocd.argoproj.io/sync-wave: "2"
        argocd.argoproj.io/sync-options: "Prune=false"
    spec:
      project: "platform-management"
      source:
        repoURL: "https://github.com/org/repo"
        targetRevision: "HEAD"
        path: "groups/kustomize/groups/dev-protected"
```

### Protection Mechanisms

1. **Sync Wave**: Deployed after critical components (wave 2)
2. **Prune Protection**: Prune=false prevents deletion
3. **Medium Protection**: Marked as medium protection level
4. **Environment Isolation**: Development-specific configurations

## 🚀 Usage Examples

### 1. Deploy Development Protected Capabilities

```bash
# Deploy via ApplicationSet (recommended)
# The ApplicationSet will automatically deploy all protected capabilities

# Manual deployment (for testing)
kustomize build capabilities/storage/ | oc apply -f -
```

### 2. Verify Protection

```bash
# Check protection annotations
oc get applications -n openshift-gitops -o yaml | grep -A 5 -B 5 "Prune=false"

# Check sync waves
oc get applications -n openshift-gitops -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.metadata.annotations.argocd\.argoproj\.io/sync-wave}{"\n"}{end}'

# Check protection labels
oc get applications -n openshift-gitops -l protection-level=medium
```

### 3. Manage Storage

```bash
# Check storage classes
oc get storageclass

# Check persistent volumes
oc get persistentvolume

# Check storage quotas
oc get resourcequota -A | grep storage
```

## 🚨 Troubleshooting

### Common Issues

1. **Storage Configuration Issues**
   ```bash
   # Check storage classes
   oc get storageclass
   
   # Check storage class details
   oc describe storageclass storage-class-name
   
   # Check persistent volumes
   oc get persistentvolume
   ```

2. **Protection Not Working**
   ```bash
   # Check protection annotations
   oc get applications -n openshift-gitops -o yaml | grep -A 5 -B 5 "Prune=false"
   
   # Check sync waves
   oc get applications -n openshift-gitops -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.metadata.annotations.argocd\.argoproj\.io/sync-wave}{"\n"}{end}'
   ```

3. **ApplicationSet Issues**
   ```bash
   # Check ApplicationSet status
   oc get applicationsets -n openshift-gitops
   
   # Check ApplicationSet logs
   oc logs -n openshift-gitops deployment/argocd-applicationset-controller
   
   # Check cluster labels
   oc get managedclusters -o yaml | grep -A 5 -B 5 "cluster-type"
   ```

### Debug Mode

Enable debug mode for detailed troubleshooting:

```bash
# Kustomize debug
kustomize build capabilities/storage/ --enable-helm --enable-alpha-plugins

# ApplicationSet debug
oc patch applicationset dev-protected-capabilities -n openshift-gitops --type merge -p '{"spec":{"template":{"spec":{"syncPolicy":{"syncOptions":["CreateNamespace=true"]}}}}}'

# Storage debug
oc get storageclass -o yaml | grep -A 10 -B 10 "parameters"
```

### Log Analysis

```bash
# Check ArgoCD logs
oc logs -n openshift-gitops deployment/argocd-server
oc logs -n openshift-gitops deployment/argocd-application-controller

# Check storage logs
oc logs -n openshift-storage deployment/csi-driver

# Check protection logs
oc get events -n openshift-gitops --sort-by='.lastTimestamp' | grep -i "prune"
```

## 🤝 Contributing

### Development Workflow

1. **Create Feature Branch**:
   ```bash
   git checkout -b feature/dev-protected-update
   ```

2. **Make Changes**:
   - Add new protected capabilities
   - Modify existing capabilities
   - Update documentation

3. **Test Changes**:
   ```bash
   # Test capability build
   kustomize build capabilities/capability-name/
   
   # Test with ApplicationSet
   oc apply -f applicationset.yaml
   ```

4. **Create Pull Request**:
   - Include description of changes
   - Reference any related issues
   - Ensure all tests pass

### Code Standards

- **Consistent Structure**: Follow established directory structure
- **Documentation**: Include README.md for new capabilities
- **Testing**: Add tests for new functionality
- **Naming**: Use descriptive, consistent naming conventions

## 📄 License

This project is part of the ODFL OpenShift vSphere IPI Installation automation framework.

---

**Note**: Always test protected capability changes in a development environment before deploying to production. Consider the impact of changes on development workflows and resource protection.