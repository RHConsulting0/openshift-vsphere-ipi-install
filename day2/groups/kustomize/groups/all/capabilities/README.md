# All Clusters Capabilities

This directory manages capabilities that are applied to all clusters regardless of type or environment, providing common functionality across the entire platform.

## 📋 Table of Contents

- [Overview](#-overview)
- [Directory Structure](#-directory-structure)
- [Common Capabilities](#-common-capabilities)
- [Configuration Management](#️-configuration-management)
- [Usage Examples](#-usage-examples)
- [Troubleshooting](#-troubleshooting)
- [Contributing](#-contributing)
- [License](#-license)

## 🎯 Overview

The all clusters capabilities directory provides:

- **Universal Configuration**: Common settings for all clusters
- **Identity Management**: Centralized identity and authentication
- **Security Policies**: Base security configurations
- **Monitoring Setup**: Common monitoring and observability

**Note**: There is no `kustomization.yaml` at this level because these capabilities are meant to be loaded by an ArgoCD ApplicationSet.

## 📁 Directory Structure

```
all/
├── README.md                           # This file
└── capabilities/
    ├── identity-configuration/         # Identity provider configuration
    │   ├── kustomization.yaml
    │   └── identity-config.yaml
    └── external-secrets-operator/      # External Secrets Operator
        ├── kustomization.yaml
        └── eso-config.yaml
```

## 🔧 Common Capabilities

### 1. Identity Configuration

**Purpose**: Centralized identity and authentication configuration

**Features:**
- Identity provider setup
- OAuth server configuration
- RBAC configuration
- User and group management

**Configuration:**
```yaml
# identity-configuration/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- identity-config.yaml

labels:
- includeSelectors: false
  pairs:
    app.kubernetes.io/part-of: platform-management
    component: identity
    scope: all-clusters
```

### 2. External Secrets Operator

**Purpose**: External secrets management across all clusters

**Features:**
- Secret store configuration
- External secret definitions
- Secret synchronization
- Security policies

**Configuration:**
```yaml
# external-secrets-operator/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- eso-config.yaml

labels:
- includeSelectors: false
  pairs:
    app.kubernetes.io/part-of: platform-management
    component: external-secrets
    scope: all-clusters
```

## ⚙️ Configuration Management

### ApplicationSet Integration

These capabilities are deployed via ArgoCD ApplicationSets to all clusters:

```yaml
# Example ApplicationSet configuration
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: all-clusters-capabilities
spec:
  generators:
  - clusters:
      selector: {}  # Apply to all clusters
  template:
    metadata:
      name: "{{name}}-all-capabilities"
    spec:
      project: "platform-management"
      source:
        repoURL: "https://github.com/org/repo"
        targetRevision: "HEAD"
        path: "groups/kustomize/groups/all/capabilities"
```

### Scope Management

Capabilities are scoped to all clusters using:

1. **Universal Selector**: Empty selector applies to all clusters
2. **Common Labels**: Consistent labeling across all clusters
3. **Global Configuration**: Settings that apply universally

## 🚀 Usage Examples

### 1. Deploy All Clusters Capabilities

```bash
# Deploy via ApplicationSet (recommended)
# The ApplicationSet will automatically deploy all capabilities to all clusters

# Manual deployment (for testing)
kustomize build capabilities/identity-configuration/ | oc apply -f -
kustomize build capabilities/external-secrets-operator/ | oc apply -f -
```

### 2. Verify Deployment

```bash
# Check applications on all clusters
oc get applications -n openshift-gitops

# Check identity configuration
oc get oauth cluster -o yaml

# Check external secrets operator
oc get pods -n external-secrets-system
```

### 3. Update Configuration

```bash
# Update identity configuration
oc patch oauth cluster --type merge -p '{"spec":{"identityProviders":[{"name":"ldap","type":"LDAP"}]}}'

# Update external secrets configuration
oc patch secretstore vault-backend -n external-secrets-system --type merge -p '{"spec":{"vault":{"server":"https://vault.example.com"}}}'
```

## 🚨 Troubleshooting

### Common Issues

1. **Identity Configuration Issues**
   ```bash
   # Check OAuth server
   oc get oauth cluster
   
   # Check OAuth server details
   oc describe oauth cluster
   
   # Check identity providers
   oc get oauth cluster -o jsonpath='{.spec.identityProviders[*].name}'
   ```

2. **External Secrets Issues**
   ```bash
   # Check ESO pods
   oc get pods -n external-secrets-system
   
   # Check secret stores
   oc get secretstore -A
   
   # Check external secrets
   oc get externalsecret -A
   ```

3. **ApplicationSet Issues**
   ```bash
   # Check ApplicationSet status
   oc get applicationsets -n openshift-gitops
   
   # Check ApplicationSet logs
   oc logs -n openshift-gitops deployment/argocd-applicationset-controller
   
   # Check cluster discovery
   oc get managedclusters
   ```

4. **Scope Issues**
   ```bash
   # Check cluster labels
   oc get managedclusters -o yaml | grep -A 5 -B 5 "labels"
   
   # Check application scope
   oc get applications -n openshift-gitops -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.destination.server}{"\n"}{end}'
   ```

### Debug Mode

Enable debug mode for detailed troubleshooting:

```bash
# Kustomize debug
kustomize build capabilities/identity-configuration/ --enable-helm --enable-alpha-plugins

# ApplicationSet debug
oc patch applicationset all-clusters-capabilities -n openshift-gitops --type merge -p '{"spec":{"template":{"spec":{"syncPolicy":{"syncOptions":["CreateNamespace=true"]}}}}}'

# Identity debug
oc get oauth cluster -o yaml | grep -A 10 -B 10 "status"
```

### Log Analysis

```bash
# Check ArgoCD logs
oc logs -n openshift-gitops deployment/argocd-server
oc logs -n openshift-gitops deployment/argocd-application-controller

# Check identity logs
oc logs -n openshift-authentication deployment/oauth-openshift

# Check ESO logs
oc logs -n external-secrets-system deployment/external-secrets
```

## 🤝 Contributing

### Development Workflow

1. **Create Feature Branch**:
   ```bash
   git checkout -b feature/all-clusters-update
   ```

2. **Make Changes**:
   - Add new common capabilities
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

**Note**: Always test capability changes in a development environment before deploying to production. Consider the impact of changes on all clusters in the platform.
