# Lab Cluster Capabilities

This directory contains cluster-specific capabilities for the lab workload cluster, which runs applications and services in a managed environment.

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

The lab cluster capabilities directory provides cluster-specific configurations that are deployed via ArgoCD ApplicationSets. These capabilities are essential for:

- **Application Workloads**: Running business applications and services
- **Application Management**: Application configurations and isolation
- **Development Tools**: Lab-specific tools and configurations
- **Custom Environment**: Lab-specific customizations

**Note**: There is no `kustomization.yaml` at this level because these capabilities are meant to be loaded by an ArgoCD ApplicationSet.

## 📁 Directory Structure

```
capabilities/
├── README.md                                    # This file
├── application-gitops/                          # Application GitOps configuration
│   ├── kustomization.yaml
│   └── charts/
│       └── vpc-gitops/
└── web-console-cluster-customization/          # Console customization
    ├── kustomization.yaml
    └── console-customization.yaml
```

## 🔧 Capabilities

### 1. Application GitOps

**Purpose**: GitOps configuration for application management

**Features:**
- Application-specific ArgoCD instances
- Application isolation
- Resource management
- Access control

**Configuration:**
```yaml
# application-gitops/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- charts/vpc-gitops/
```

### 2. Web Console Cluster Customization

**Purpose**: Customize the OpenShift web console for lab environment

**Features:**
- Lab-specific branding
- Custom navigation links
- Development tools integration
- User interface enhancements

**Configuration:**
```yaml
# web-console-cluster-customization/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- console-customization.yaml
```

## ⚙️ Configuration Management

### ApplicationSet Integration

These capabilities are deployed via ArgoCD ApplicationSets:

```yaml
# Example ApplicationSet configuration
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: lab-capabilities
spec:
  generators:
  - clusters:
      selector:
        matchLabels:
          cluster-type: "workload"
  template:
    metadata:
      name: "{{name}}-lab-capabilities"
    spec:
      project: "platform-management"
      source:
        repoURL: "https://github.com/org/repo"
        targetRevision: "HEAD"
        path: "clusters/lab/capabilities"
```

### Capability Dependencies

Capabilities have specific dependencies:

1. **Application GitOps** → Requires ArgoCD operator
2. **Console Customization** → Requires console operator
3. **VPC GitOps** → Requires GitOps repository access

## 🚀 Usage Examples

### 1. Deploy All Lab Capabilities

```bash
# Deploy via ApplicationSet (recommended)
# The ApplicationSet will automatically deploy all capabilities

# Manual deployment (for testing)
kustomize build application-gitops/ | oc apply -f -
kustomize build web-console-cluster-customization/ | oc apply -f -
```

### 2. Deploy Specific Capability

```bash
# Deploy only application GitOps
kustomize build application-gitops/ | oc apply -f -

# Verify deployment
oc get applications -n openshift-gitops
oc get consolelink
```

### 3. Customize Capability Configuration

```bash
# Apply custom patches
kustomize build application-gitops/ --enable-patches | oc apply -f -

# Override specific values
kustomize build web-console-cluster-customization/ --enable-helm | oc apply -f -
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

2. **Application GitOps Issues**
   ```bash
   # Check application applications
   oc get applications -n openshift-gitops
   
   # Check application namespaces
   oc get namespaces -l app
   
   # Check GitOps operator
   oc get pods -n openshift-gitops
   ```

3. **Console Customization Not Applied**
   ```bash
   # Check console customization
   oc get consolelink
   
   # Check console operator
   oc get pods -n openshift-console
   
   # Check console logs
   oc logs -n openshift-console deployment/console
   ```

4. **VPC GitOps Issues**
   ```bash
   # Check VPC GitOps instance
   oc get argocd -n openshift-gitops
   
   # Check VPC GitOps pods
   oc get pods -n openshift-gitops -l app.kubernetes.io/name=argocd
   
   # Check VPC GitOps logs
   oc logs -n openshift-gitops deployment/vpc-gitops-server
   ```

### Debug Mode

Enable debug mode for detailed troubleshooting:

```bash
# Kustomize debug
kustomize build capability-name/ --enable-helm --enable-alpha-plugins

# ApplicationSet debug
oc patch applicationset lab-capabilities -n openshift-gitops --type merge -p '{"spec":{"template":{"spec":{"syncPolicy":{"syncOptions":["CreateNamespace=true"]}}}}}'

# Application debug
oc get applications -n openshift-gitops -o yaml | grep -A 10 -B 10 "application"
```

### Log Analysis

```bash
# Check ArgoCD logs
oc logs -n openshift-gitops deployment/argocd-server
oc logs -n openshift-gitops deployment/argocd-application-controller

# Check console logs
oc logs -n openshift-console deployment/console

# Check application logs
oc logs -n application-namespace deployment/application-app
```

## 🤝 Contributing

### Development Workflow

1. **Create Feature Branch**:
   ```bash
   git checkout -b feature/new-lab-capability
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

**Note**: Always test capability changes in a development environment before deploying to production. Consider the impact of changes on application isolation and application workloads.
