# Hub Protected Capabilities

This directory manages all capabilities the hub cluster will provide which need to be protected from removal. These are critical components that must not be deleted to maintain cluster functionality.

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

The hub protected capabilities directory provides:

- **Critical Hub Components**: Essential hub cluster functionality
- **Deletion Protection**: Prevents accidental removal of critical resources
- **ACM Integration**: Advanced Cluster Management core components
- **GitOps Foundation**: Essential GitOps infrastructure

**Note**: There is no `kustomization.yaml` at this level because these capabilities are meant to be loaded by an ArgoCD ApplicationSet.

## 📁 Directory Structure

```
hub-protected/
├── README.md                           # This file
└── capabilities/
    ├── acm-hub/                        # ACM hub configuration
    │   ├── kustomization.yaml
    │   └── acm-hub-config.yaml
    └── acm-operator/                   # ACM operator
        ├── kustomization.yaml
        └── acm-operator.yaml
```

## 🛡️ Protected Capabilities

### 1. ACM Hub Configuration

**Purpose**: Advanced Cluster Management hub cluster configuration

**Protection Level**: Critical - Prevents cascade deletion

**Features:**
- Multi-cluster management
- Policy enforcement
- Cluster registration
- Centralized monitoring

**Configuration:**
```yaml
# acm-hub/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- acm-hub-config.yaml

labels:
- includeSelectors: false
  pairs:
    app.kubernetes.io/part-of: platform-management
    protection-level: critical
    component: acm-hub
```

### 2. ACM Operator

**Purpose**: Advanced Cluster Management operator installation

**Protection Level**: Critical - Core ACM functionality

**Features:**
- ACM operator deployment
- Multi-cluster coordination
- Policy management
- Cluster lifecycle management

**Configuration:**
```yaml
# acm-operator/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- acm-operator.yaml

labels:
- includeSelectors: false
  pairs:
    app.kubernetes.io/part-of: platform-management
    protection-level: critical
    component: acm-operator
```

## ⚙️ Configuration Management

### ApplicationSet Integration

These capabilities are deployed via ArgoCD ApplicationSets with protection:

```yaml
# Example ApplicationSet configuration
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: hub-protected-capabilities
  annotations:
    argocd.argoproj.io/sync-wave: "1"
    argocd.argoproj.io/sync-options: "Prune=false"
spec:
  generators:
  - clusters:
      selector:
        matchLabels:
          cluster-type: "hub"
  template:
    metadata:
      name: "{{name}}-hub-protected"
      annotations:
        argocd.argoproj.io/sync-wave: "1"
        argocd.argoproj.io/sync-options: "Prune=false"
    spec:
      project: "platform-management"
      source:
        repoURL: "https://github.com/org/repo"
        targetRevision: "HEAD"
        path: "groups/kustomize/groups/hub-protected"
```

### Protection Mechanisms

1. **Sync Wave**: Deployed first (wave 1)
2. **Prune Protection**: Prune=false prevents deletion
3. **Critical Labels**: Marked as critical components
4. **Dependency Management**: Other components depend on these

## 🚀 Usage Examples

### 1. Deploy Protected Capabilities

```bash
# Deploy via ApplicationSet (recommended)
# The ApplicationSet will automatically deploy all protected capabilities

# Manual deployment (for testing)
kustomize build capabilities/acm-hub/ | oc apply -f -
kustomize build capabilities/acm-operator/ | oc apply -f -
```

### 2. Verify Protection

```bash
# Check protection annotations
oc get applications -n openshift-gitops -o yaml | grep -A 5 -B 5 "Prune=false"

# Check sync waves
oc get applications -n openshift-gitops -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.metadata.annotations.argocd\.argoproj\.io/sync-wave}{"\n"}{end}'

# Check protection labels
oc get applications -n openshift-gitops -l protection-level=critical
```

### 3. Emergency Override

```bash
# Remove protection (emergency only)
oc patch application hub-protected-capabilities -n openshift-gitops --type merge -p '{"metadata":{"annotations":{"argocd.argoproj.io/sync-options":"Prune=true"}}}'

# Re-enable protection
oc patch application hub-protected-capabilities -n openshift-gitops --type merge -p '{"metadata":{"annotations":{"argocd.argoproj.io/sync-options":"Prune=false"}}}'
```

## 🚨 Troubleshooting

### Common Issues

1. **Protected Capabilities Not Deploying**
   ```bash
   # Check ApplicationSet status
   oc get applicationsets -n openshift-gitops
   
   # Check ApplicationSet logs
   oc logs -n openshift-gitops deployment/argocd-applicationset-controller
   
   # Check cluster labels
   oc get managedclusters -o yaml | grep -A 5 -B 5 "cluster-type"
   ```

2. **ACM Hub Issues**
   ```bash
   # Check ACM hub status
   oc get pods -n open-cluster-management
   
   # Check ACM hub logs
   oc logs -n open-cluster-management deployment/multicluster-observability-operator
   
   # Check ACM hub configuration
   oc get multiclusterhub -A
   ```

3. **ACM Operator Issues**
   ```bash
   # Check ACM operator status
   oc get pods -n open-cluster-management
   
   # Check ACM operator logs
   oc logs -n open-cluster-management deployment/multicluster-observability-operator
   
   # Check ACM operator configuration
   oc get subscription -n open-cluster-management
   ```

4. **Protection Not Working**
   ```bash
   # Check protection annotations
   oc get applications -n openshift-gitops -o yaml | grep -A 5 -B 5 "Prune=false"
   
   # Check sync waves
   oc get applications -n openshift-gitops -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.metadata.annotations.argocd\.argoproj\.io/sync-wave}{"\n"}{end}'
   ```

### Debug Mode

Enable debug mode for detailed troubleshooting:

```bash
# Kustomize debug
kustomize build capabilities/acm-hub/ --enable-helm --enable-alpha-plugins

# ApplicationSet debug
oc patch applicationset hub-protected-capabilities -n openshift-gitops --type merge -p '{"spec":{"template":{"spec":{"syncPolicy":{"syncOptions":["CreateNamespace=true"]}}}}}'

# ACM debug
oc get multiclusterhub -A -o yaml | grep -A 10 -B 10 "status"
```

### Log Analysis

```bash
# Check ArgoCD logs
oc logs -n openshift-gitops deployment/argocd-server
oc logs -n openshift-gitops deployment/argocd-application-controller

# Check ACM logs
oc logs -n open-cluster-management deployment/multicluster-observability-operator
oc logs -n open-cluster-management deployment/governance-policy-framework

# Check protection logs
oc get events -n openshift-gitops --sort-by='.lastTimestamp' | grep -i "prune"
```

## 🤝 Contributing

### Development Workflow

1. **Create Feature Branch**:
   ```bash
   git checkout -b feature/hub-protected-update
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

**Note**: Always test protected capability changes in a development environment before deploying to production. Consider the impact of changes on cluster stability and protection mechanisms.
