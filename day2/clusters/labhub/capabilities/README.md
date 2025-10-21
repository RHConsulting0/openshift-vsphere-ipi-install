# Hub Lab Capabilities

This directory contains cluster-specific capabilities for the hub lab cluster, which manages multiple workload clusters through Advanced Cluster Management (ACM) and GitOps.

## 📋 Table of Contents

- [Overview](#-overview)
- [Directory Structure](#-directory-structure)
- [Capabilities](#-capabilities)
- [Configuration Management](#️-configuration-management)
- [Usage Examples](#-usage-examples)
- [Troubleshooting](#-troubleshooting)
- [Contributing](#-contributing)
- [License](#-license)

## 🎯 Overview

The hub lab capabilities directory provides cluster-specific configurations that are deployed via ArgoCD ApplicationSets. These capabilities are essential for:

- **Multi-Cluster Management**: Managing multiple workload clusters
- **Policy Enforcement**: Ensuring consistent configuration across clusters
- **Centralized Monitoring**: Monitoring all managed clusters
- **GitOps Coordination**: Coordinating GitOps deployments

**Note**: There is no `kustomization.yaml` at this level because these capabilities are meant to be loaded by an ArgoCD ApplicationSet.

## 📁 Directory Structure

```
capabilities/
├── README.md                                    # This file
├── acm-policies-openshift-gitops/              # ACM policies for GitOps
│   ├── kustomization.yaml
│   ├── cluster-gitops-repository-configuration/
│   └── README.md
├── custom-cluster-name/                        # Custom cluster naming
│   ├── kustomization.yaml
│   ├── cluster-name-patch.yaml
│   └── README-hack.md
├── managed-clusters/                           # Managed cluster configurations
│   ├── kustomization.yaml
│   └── lab/
│       └── cluster-gitops-repository-configuration/
└── web-console-cluster-customization/          # Console customization
    ├── kustomization.yaml
    └── console-customization.yaml
```

## 🔧 Capabilities

### 1. ACM Policies OpenShift GitOps

**Purpose**: Advanced Cluster Management policies for GitOps configuration

**Features:**
- Policy enforcement across managed clusters
- GitOps repository configuration
- Compliance monitoring
- Automated remediation

**Configuration:**
```yaml
# acm-policies-openshift-gitops/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- cluster-gitops-repository-configuration/
```

### 2. Custom Cluster Name

**Purpose**: Customize cluster naming for ACM management

**Features:**
- Override default cluster names
- Support for multiple ACM instances
- Cluster identification and management

**Note**: This is a temporary workaround for ACM-1290. See [README-hack.md](custom-cluster-name/README-hack.md) for details.

### 3. Managed Clusters

**Purpose**: Configuration for managed workload clusters

**Features:**
- Cluster registration and management
- GitOps repository configuration
- Cluster-specific settings

### 4. Web Console Cluster Customization

**Purpose**: Customize the OpenShift web console

**Features:**
- Console branding and customization
- Custom links and navigation
- User interface enhancements

## ⚙️ Configuration Management

### ApplicationSet Integration

These capabilities are deployed via ArgoCD ApplicationSets:

```yaml
# Example ApplicationSet configuration
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: hub-lab-capabilities
spec:
  generators:
  - clusters:
      selector:
        matchLabels:
          cluster-type: "hub"
  template:
    metadata:
      name: "{{name}}-hub-capabilities"
    spec:
      project: "platform-management"
      source:
        repoURL: "https://github.com/org/repo"
        targetRevision: "HEAD"
        path: "clusters/labhub/capabilities"
```

### Capability Dependencies

Capabilities have specific dependencies:

1. **ACM Policies** → Requires ACM operator
2. **Managed Clusters** → Requires cluster registration
3. **Console Customization** → Requires console operator
4. **Custom Cluster Name** → Requires ACM hub

## 🚀 Usage Examples

### 1. Deploy All Hub Capabilities

```bash
# Deploy via ApplicationSet (recommended)
# The ApplicationSet will automatically deploy all capabilities

# Manual deployment (for testing)
kustomize build acm-policies-openshift-gitops/ | oc apply -f -
kustomize build custom-cluster-name/ | oc apply -f -
kustomize build managed-clusters/ | oc apply -f -
kustomize build web-console-cluster-customization/ | oc apply -f -
```

### 2. Deploy Specific Capability

```bash
# Deploy only ACM policies
kustomize build acm-policies-openshift-gitops/ | oc apply -f -

# Verify deployment
oc get policies -A
oc get applications -n openshift-gitops
```

### 3. Customize Capability Configuration

```bash
# Apply custom patches
kustomize build acm-policies-openshift-gitops/ --enable-patches | oc apply -f -

# Override specific values
kustomize build managed-clusters/ --enable-helm | oc apply -f -
```

## 🚨 Troubleshooting

### Common Issues

1. **ApplicationSet Not Deploying Capabilities**
   ```bash
   # Check ApplicationSet status
   oc get applicationsets -n openshift-gitops
   
   # Check ApplicationSet logs
   oc logs -n openshift-gitops deployment/argocd-applicationset-controller
   
   # Verify cluster labels
   oc get managedclusters -o yaml | grep -A 5 -B 5 "cluster-type"
   ```

2. **ACM Policies Not Applied**
   ```bash
   # Check policy status
   oc get policies -A
   
   # Check policy compliance
   oc describe policy gitops-repository-configuration
   
   # Check ACM operator status
   oc get pods -n open-cluster-management
   ```

3. **Managed Cluster Registration Issues**
   ```bash
   # Check managed cluster status
   oc get managedclusters
   
   # Check cluster registration
   oc describe managedcluster cluster-name
   
   # Check cluster secrets
   oc get secrets -n open-cluster-management
   ```

4. **Console Customization Not Applied**
   ```bash
   # Check console customization
   oc get consolelink
   
   # Check console operator
   oc get pods -n openshift-console
   
   # Check console logs
   oc logs -n openshift-console deployment/console
   ```

### Debug Mode

Enable debug mode for detailed troubleshooting:

```bash
# Kustomize debug
kustomize build capability-name/ --enable-helm --enable-alpha-plugins

# ApplicationSet debug
oc patch applicationset hub-lab-capabilities -n openshift-gitops --type merge -p '{"spec":{"template":{"spec":{"syncPolicy":{"syncOptions":["CreateNamespace=true"]}}}}}'

# ACM debug
oc get policies -A -o yaml | grep -A 10 -B 10 "status"
```

### Log Analysis

```bash
# Check ArgoCD logs
oc logs -n openshift-gitops deployment/argocd-server
oc logs -n openshift-gitops deployment/argocd-application-controller

# Check ACM logs
oc logs -n open-cluster-management deployment/multicluster-observability-operator
oc logs -n open-cluster-management deployment/governance-policy-framework

# Check console logs
oc logs -n openshift-console deployment/console
```

## 🤝 Contributing

### Development Workflow

1. **Create Feature Branch**:
   ```bash
   git checkout -b feature/new-hub-capability
   ```

2. **Make Changes**:
   - Add new capability configurations
   - Modify existing capabilities
   - Update documentation

3. **Test Changes**:
   ```bash
   # Test capability build
   kustomize build capability-name/
   
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

**Note**: Always test capability changes in a development environment before deploying to production. Consider the impact of changes on managed clusters and policy enforcement.
