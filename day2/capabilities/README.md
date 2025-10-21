# Capabilities - Reusable Components

This directory contains reusable capabilities and components that can be deployed across multiple OpenShift clusters using GitOps principles.

## 📋 Table of Contents

- [Overview](#-overview)
- [Directory Structure](#-directory-structure)
- [Helm Charts](#-helm-charts)
- [Kustomize Bases](#-kustomize-bases)
- [Testing](#-testing)
- [Usage Examples](#-usage-examples)
- [Customization](#-customization)
- [Troubleshooting](#-troubleshooting)
- [Contributing](#-contributing)
- [License](#-license)

## 🎯 Overview

The capabilities directory provides a library of reusable components for OpenShift cluster management, including:

- **Helm Charts**: Packaged applications with configurable values
- **Kustomize Bases**: Base configurations for common capabilities
- **Testing Framework**: Automated validation of all components

### Key Features

- **Reusability**: Components can be used across multiple clusters
- **Consistency**: Standardized configurations ensure consistency
- **Flexibility**: Both Helm and Kustomize support for different use cases
- **Validation**: Comprehensive testing framework
- **Documentation**: Detailed documentation for each capability

## 📁 Directory Structure

```
capabilities/
├── README.md                           # This file
├── helm/                              # Helm charts
│   └── charts/
│       ├── application-set/           # ArgoCD ApplicationSet chart
│       ├── compute-gitops/            # GitOps instance chart
│       └── operators-installer-3.2.4/ # Operator installation chart
├── kustomize/                         # Kustomize base configurations
│   └── bases/
│       ├── acm-hub/                   # ACM hub configuration
│       ├── acm-operator/              # ACM operator installation
│       ├── external-secrets-operator/ # External Secrets Operator
│       ├── identity-configuration/    # Identity provider config
│       ├── kubelet-configuration/     # Kubelet tuning
│       ├── node-maintenance-operator/ # Node maintenance
│       ├── oauth-configuration/       # OAuth configuration
│       └── openshift-gitops/          # OpenShift GitOps
└── tests/                             # Validation tests
    └── test-all-kustomization-builds-playbook.yaml
├── helm/                              # Helm charts for capabilities
│   └── charts/
│       ├── application-set/           # ArgoCD ApplicationSet management
│       │   ├── Chart.yaml
│       │   ├── values.yaml
│       │   └── templates/
│       │       └── ApplicationSet.yaml
│       └── compute-gitops/            # Compute cluster GitOps configuration
│           ├── Chart.yaml
│           ├── values.yaml
│           └── templates/
│               ├── AppProject_default.yaml
│               ├── ClusterRole_vpc-admin.yaml
│               ├── ClusterRoleBinding_vpc-admin.yaml
│               ├── ArgoCD_vpc-gitops.yaml
│               ├── AppProject_vpc-management.yaml
│               └── ConsoleLink.yaml
├── kustomize/                         # Kustomize base configurations
│   └── bases/
│       ├── acm-hub/                   # ACM hub configuration
│       ├── acm-policies-openshift-gitops/  # ACM policies for GitOps
│       ├── cluster-gitops-repository-configuration/  # GitOps repo config
│       ├── external-secrets-configuration/  # External secrets configuration
│       ├── external-secrets-operator/       # External Secrets Operator
│       ├── groupsync-configuration/         # Group synchronization
│       ├── identity-configuration/          # Identity provider configuration
│       ├── kubelet-configuration/           # Kubelet tuning and configuration
│       ├── node-maintenance-operator/       # Node maintenance operator
│       ├── oauth-configuration/             # OAuth server configuration
│       ├── openshift-gitops/                # OpenShift GitOps operator
│       └── openshift-gitops-operator/       # GitOps operator installation
└── tests/                             # Capability validation tests
    └── test-all-kustomization-builds-playbook.yaml
```

## 🚀 Helm Charts

### Application Set Chart

The `application-set` chart provides ArgoCD ApplicationSet management capabilities:

**Features:**
- Automated cluster discovery
- Dynamic application deployment
- Configurable sync policies
- Multi-environment support

**Usage:**
```yaml
# values.yaml
applicationSetDefaults:
  componentLabel: "platform-management"
  partOfLabel: "platform-management"
  argoCDProject: "platform-management"
  syncPolicyAutomated: true
```

**Deployment:**
```bash
helm install application-set ./charts/application-set/ \
  --values values.yaml \
  --namespace openshift-gitops
```

### Compute GitOps Chart

The `compute-gitops` chart configures GitOps for compute clusters:

**Features:**
- ArgoCD instance configuration
- AppProject management
- Cluster role and binding setup
- Console link integration

**Usage:**
```yaml
# values.yaml
argoCD:
  namespace: "openshift-gitops"
  instance: "vpc-gitops"
  
appProjects:
  - name: "vpc-management"
    description: "VPC Management Project"
```

**Deployment:**
```bash
helm install compute-gitops ./charts/compute-gitops/ \
  --values values.yaml \
  --namespace openshift-gitops
```

## 🔧 Kustomize Bases

### ACM Hub Configuration

**Purpose**: Advanced Cluster Management hub cluster configuration

**Components:**
- ACM operator installation
- Hub cluster policies
- Multi-cluster management setup

**Usage:**
```yaml
# kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- acm-operator.yaml
- hub-policies.yaml
```

### External Secrets Configuration

**Purpose**: External Secrets Operator configuration and management

**Components:**
- ESO operator installation
- Secret store configurations
- External secret definitions

**Usage:**
```yaml
# kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- external-secrets-operator.yaml
- secret-store-config.yaml
```

### Kubelet Configuration

**Purpose**: Kubelet tuning and performance optimization

**Components:**
- Node sizing configuration
- Pod limits configuration
- Resource allocation settings

**Usage:**
```yaml
# kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- kubelet-config.yaml
- node-sizing.yaml
```

### OAuth Configuration

**Purpose**: OAuth server configuration and identity provider setup

**Components:**
- OAuth server configuration
- Identity provider setup
- RBAC configuration

**Usage:**
```yaml
# kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- oauth-config.yaml
- identity-providers.yaml
```

## 🧪 Testing

### Automated Validation

The capabilities directory includes comprehensive testing:

```bash
# Test all Kustomize builds
ansible-playbook tests/test-all-kustomization-builds-playbook.yaml

# Test specific capability
kustomize build kustomize/bases/openshift-gitops/

# Test Helm chart
helm template application-set ./helm/charts/application-set/
```

### Test Coverage

- **Kustomize Build Validation**: Ensures all base configurations build successfully
- **Helm Chart Validation**: Validates chart templates and values
- **Resource Validation**: Checks for proper Kubernetes resource definitions
- **Dependency Validation**: Ensures all dependencies are satisfied

## 📚 Usage Examples

### 1. Deploy OpenShift GitOps

```bash
# Build and apply GitOps configuration
kustomize build kustomize/bases/openshift-gitops/ | oc apply -f -

# Verify deployment
oc get pods -n openshift-gitops
```

### 2. Configure External Secrets

```bash
# Deploy External Secrets Operator
kustomize build kustomize/bases/external-secrets-operator/ | oc apply -f -

# Configure secret stores
kustomize build kustomize/bases/external-secrets-configuration/ | oc apply -f -
```

### 3. Set Up ACM Hub

```bash
# Deploy ACM hub configuration
kustomize build kustomize/bases/acm-hub/ | oc apply -f -

# Verify ACM installation
oc get pods -n open-cluster-management
```

### 4. Configure OAuth

```bash
# Deploy OAuth configuration
kustomize build kustomize/bases/oauth-configuration/ | oc apply -f -

# Verify OAuth server
oc get oauth cluster -o yaml
```

## 🔧 Customization

### Adding New Capabilities

1. **Create Base Directory**:
   ```bash
   mkdir kustomize/bases/new-capability
   cd kustomize/bases/new-capability
   ```

2. **Create Kustomization**:
   ```yaml
   # kustomization.yaml
   apiVersion: kustomize.config.k8s.io/v1beta1
   kind: Kustomization
   
   resources:
   - resource1.yaml
   - resource2.yaml
   ```

3. **Add Documentation**:
   ```bash
   # Create README.md
   echo "# New Capability" > README.md
   ```

4. **Test Configuration**:
   ```bash
   kustomize build kustomize/bases/new-capability/
   ```

### Modifying Existing Capabilities

1. **Edit Configuration Files**:
   ```bash
   vim kustomize/bases/existing-capability/kustomization.yaml
   ```

2. **Test Changes**:
   ```bash
   kustomize build kustomize/bases/existing-capability/
   ```

3. **Run Full Test Suite**:
   ```bash
   ansible-playbook tests/test-all-kustomization-builds-playbook.yaml
   ```

## 🚨 Troubleshooting

### Common Issues

1. **Kustomize Build Failures**
   ```bash
   # Check for missing resources
   kustomize build kustomize/bases/capability-name/
   
   # Verify resource references
   grep -r "kind:" kustomize/bases/capability-name/
   ```

2. **Helm Chart Issues**
   ```bash
   # Validate chart syntax
   helm lint ./helm/charts/chart-name/
   
   # Test chart rendering
   helm template chart-name ./helm/charts/chart-name/
   ```

3. **Resource Conflicts**
   ```bash
   # Check for duplicate resources
   oc get all -A | grep resource-name
   
   # Check resource status
   oc describe resource-type resource-name
   ```

### Debug Mode

Enable debug mode for detailed troubleshooting:

```bash
# Kustomize debug
kustomize build --enable-helm --enable-alpha-plugins kustomize/bases/capability-name/

# Helm debug
helm template chart-name ./helm/charts/chart-name/ --debug --dry-run
```

## 🤝 Contributing

### Development Workflow

1. **Create Feature Branch**:
   ```bash
   git checkout -b feature/new-capability
   ```

2. **Make Changes**:
   - Add new capability configurations
   - Update documentation
   - Add tests

3. **Test Changes**:
   ```bash
   # Run validation tests
   ansible-playbook tests/test-all-kustomization-builds-playbook.yaml
   ```

4. **Create Pull Request**:
   - Include description of changes
   - Reference any related issues
   - Ensure all tests pass

### Code Standards

- **YAML Formatting**: Use consistent indentation and formatting
- **Documentation**: Include README.md for new capabilities
- **Testing**: Add tests for new functionality
- **Naming**: Use descriptive, consistent naming conventions

## 📄 License

This project is part of the ODFL OpenShift vSphere IPI Installation automation framework.

---

**Note**: Always test capability changes in a development environment before deploying to production clusters.