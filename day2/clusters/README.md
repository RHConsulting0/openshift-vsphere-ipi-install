# Clusters - Individual Cluster Configurations

This directory contains specific configurations for individual OpenShift clusters, including hub clusters and workload clusters.

## 📋 Table of Contents

- [Overview](#-overview)
- [Directory Structure](#-directory-structure)
- [Cluster Types](#-cluster-types)
- [Configuration Management](#️-configuration-management)
- [Usage Examples](#-usage-examples)
- [Testing](#-testing)
- [Customization](#-customization)
- [Troubleshooting](#-troubleshooting)
- [Cluster Management](#-cluster-management)
- [Contributing](#-contributing)
- [License](#-license)

## 🎯 Overview

The clusters directory provides cluster-specific configurations that build upon the base capabilities defined in the `capabilities/` directory. Each cluster has its own:

- **Specific Capabilities**: Cluster-specific configurations and customizations
- **Management GitOps**: ArgoCD applications for cluster management
- **Customization**: Environment-specific settings and overrides

## 📁 Directory Structure

```
clusters/
├── README.md                           # This file
├── hub-lab/                           # Hub lab cluster configuration
│   ├── capabilities/                  # Hub-specific capabilities
│   │   ├── acm-policies-openshift-gitops/  # ACM policies for GitOps
│   │   │   ├── kustomization.yaml
│   │   │   ├── cluster-gitops-repository-configuration/
│   │   │   └── README.md
│   │   ├── custom-cluster-name/       # Custom cluster naming
│   │   │   ├── kustomization.yaml
│   │   │   └── cluster-name-patch.yaml
│   │   ├── managed-clusters/          # Managed cluster configurations
│   │   │   ├── kustomization.yaml
│   │   │   └── lab/
│   │   │       └── cluster-gitops-repository-configuration/
│   │   └── web-console-cluster-customization/  # Console customization
│   │       ├── kustomization.yaml
│   │       └── console-customization.yaml
│   ├── cluster-management-gitops/     # Cluster management GitOps
│   │   ├── application-set-values.yaml
│   │   ├── kustomization.yaml
│   │   └── charts/
│   │       └── cluster-management-gitops/
│   └── kustomization.yaml             # Hub lab main kustomization
└── lab/                               # Lab workload cluster configuration
    ├── capabilities/                  # Lab-specific capabilities
    │   ├── tenant-gitops/             # Tenant GitOps configuration
    │   │   ├── kustomization.yaml
    │   │   └── charts/
    │   │       └── vpc-gitops/
    │   └── web-console-cluster-customization/  # Console customization
    │       ├── kustomization.yaml
    │       └── console-customization.yaml
    ├── cluster-management-gitops/     # Cluster management GitOps
    │   ├── application-set-values.yaml
    │   ├── kustomization.yaml
    │   └── charts/
    │       └── cluster-management-gitops/
    └── kustomization.yaml             # Lab cluster main kustomization
```

## 🏗️ Cluster Types

### 1. Hub Lab Cluster (`hub-lab/`)

**Purpose**: Central hub cluster for managing multiple workload clusters

**Key Features:**
- **Multi-Cluster Management**: Manages multiple workload clusters
- **ACM Integration**: Advanced Cluster Management for policy enforcement
- **Centralized GitOps**: Manages GitOps configurations for all clusters
- **Policy Enforcement**: Ensures consistent configuration across clusters

**Capabilities:**
- ACM policies for OpenShift GitOps
- Custom cluster naming
- Managed cluster configurations
- Web console customization
- Centralized monitoring and logging

**Usage:**
```bash
# Deploy hub lab cluster configuration
kustomize build clusters/hub-lab/ | oc apply -f -

# Verify hub cluster deployment
oc get applications -n openshift-gitops
oc get managedclusters
```

### 2. Lab Workload Cluster (`lab/`)

**Purpose**: Workload cluster for running applications and services

**Key Features:**
- **Application Workloads**: Runs business applications and services
- **Tenant Support**: Multi-tenant configurations and isolation
- **GitOps Integration**: Managed by hub cluster through GitOps
- **Customized Environment**: Lab-specific configurations and tools

**Capabilities:**
- Tenant GitOps configuration
- Web console customization
- Lab-specific tools and configurations
- Development and testing environments

**Usage:**
```bash
# Deploy lab cluster configuration
kustomize build clusters/lab/ | oc apply -f -

# Verify lab cluster deployment
oc get applications -n openshift-gitops
oc get tenants
```

## ⚙️ Configuration Management

### Kustomize Structure

Each cluster follows a consistent Kustomize structure:

```yaml
# Example: clusters/hub-lab/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

labels:
- includeSelectors: false
  pairs:
    app.kubernetes.io/part-of: platform-management

resources:
- cluster-management-gitops
```

### Cluster-Specific Capabilities

Each cluster includes capabilities specific to its role:

**Hub Lab Capabilities:**
- ACM policies and management
- Multi-cluster coordination
- Centralized monitoring
- Policy enforcement

**Lab Capabilities:**
- Tenant management
- Application workloads
- Development tools
- Testing frameworks

### ApplicationSet Integration

Both clusters use ArgoCD ApplicationSets for automated management:

```yaml
# Example: cluster-management-gitops/application-set-values.yaml
applicationSetDefaults:
  componentLabel: "platform-management"
  partOfLabel: "platform-management"
  argoCDProject: "platform-management"
  syncPolicyAutomated: true
```

## 🚀 Usage Examples

### 1. Deploy Hub Lab Cluster

```bash
# Deploy complete hub lab configuration
kustomize build clusters/hub-lab/ | oc apply -f -

# Verify hub cluster components
oc get applications -n openshift-gitops
oc get managedclusters
oc get policies -A
```

### 2. Deploy Lab Workload Cluster

```bash
# Deploy complete lab cluster configuration
kustomize build clusters/lab/ | oc apply -f -

# Verify lab cluster components
oc get applications -n openshift-gitops
oc get tenants
oc get consolelink
```

### 3. Deploy Specific Capabilities

```bash
# Deploy only ACM policies
kustomize build clusters/hub-lab/capabilities/acm-policies-openshift-gitops/ | oc apply -f -

# Deploy only tenant GitOps
kustomize build clusters/lab/capabilities/tenant-gitops/ | oc apply -f -
```

### 4. Customize Cluster Configurations

```bash
# Apply custom patches
kustomize build clusters/hub-lab/ --enable-patches | oc apply -f -

# Override specific values
kustomize build clusters/lab/ --enable-helm | oc apply -f -
```

## 🧪 Testing

### Automated Validation

The clusters directory includes comprehensive testing:

```bash
# Test all cluster configurations
ansible-playbook tests/test-all-kustomization-builds-playbook.yaml

# Test specific cluster
kustomize build clusters/hub-lab/

# Test with validation
kustomize build clusters/lab/ | oc apply --dry-run=client -f -
```

### Test Coverage

- **Kustomize Build Validation**: Ensures all cluster configurations build successfully
- **Resource Validation**: Checks for proper Kubernetes resource definitions
- **ApplicationSet Validation**: Verifies ArgoCD ApplicationSet configurations
- **Capability Validation**: Ensures all capabilities are properly configured

## 🔧 Customization

### Adding New Clusters

1. **Create Cluster Directory**:
   ```bash
   mkdir clusters/new-cluster
   cd clusters/new-cluster
   ```

2. **Create Main Kustomization**:
   ```yaml
   # kustomization.yaml
   apiVersion: kustomize.config.k8s.io/v1beta1
   kind: Kustomization
   
   labels:
   - includeSelectors: false
     pairs:
       app.kubernetes.io/part-of: platform-management
   
   resources:
   - cluster-management-gitops
   ```

3. **Add Cluster Capabilities**:
   ```bash
   mkdir capabilities
   # Add cluster-specific capabilities
   ```

4. **Create Cluster Management GitOps**:
   ```bash
   mkdir cluster-management-gitops
   # Add GitOps configuration
   ```

5. **Test Configuration**:
   ```bash
   kustomize build clusters/new-cluster/
   ```

### Modifying Existing Clusters

1. **Edit Cluster Configuration**:
   ```bash
   vim clusters/existing-cluster/kustomization.yaml
   ```

2. **Add or Remove Capabilities**:
   ```yaml
   resources:
   - capabilities/new-capability/
   # - capabilities/removed-capability/  # Comment out to remove
   ```

3. **Test Changes**:
   ```bash
   kustomize build clusters/existing-cluster/
   ```

### Adding New Capabilities

1. **Create Capability Directory**:
   ```bash
   mkdir clusters/cluster-name/capabilities/new-capability
   cd clusters/cluster-name/capabilities/new-capability
   ```

2. **Create Capability Configuration**:
   ```yaml
   # kustomization.yaml
   apiVersion: kustomize.config.k8s.io/v1beta1
   kind: Kustomization
   
   resources:
   - resource1.yaml
   - resource2.yaml
   ```

3. **Update Cluster Kustomization**:
   ```yaml
   # Add to cluster kustomization.yaml
   resources:
   - capabilities/new-capability/
   ```

## 🚨 Troubleshooting

### Common Issues

1. **Cluster Build Failures**
   ```bash
   # Check for missing capabilities
   kustomize build clusters/cluster-name/
   
   # Verify capability references
   grep -r "capabilities/" clusters/cluster-name/
   ```

2. **ApplicationSet Issues**
   ```bash
   # Check ApplicationSet status
   oc get applicationsets -n openshift-gitops
   
   # Verify ApplicationSet configuration
   oc describe applicationset cluster-management-gitops -n openshift-gitops
   ```

3. **Capability Dependencies**
   ```bash
   # Check capability dependencies
   oc get applications -n openshift-gitops
   
   # Verify capability status
   oc describe application capability-name -n openshift-gitops
   ```

### Debug Mode

Enable debug mode for detailed troubleshooting:

```bash
# Kustomize debug
kustomize build --enable-helm --enable-alpha-plugins clusters/cluster-name/

# Resource validation
kustomize build clusters/cluster-name/ | oc apply --dry-run=client -f -
```

## 📊 Cluster Management

### Hub Lab Cluster Management

- **Multi-Cluster Coordination**: Manages multiple workload clusters
- **Policy Enforcement**: Ensures consistent configuration
- **Centralized Monitoring**: Monitors all managed clusters
- **GitOps Management**: Manages GitOps configurations

### Lab Cluster Management

- **Application Workloads**: Runs business applications
- **Tenant Isolation**: Provides multi-tenant support
- **Development Tools**: Supports development and testing
- **Custom Configurations**: Lab-specific customizations

### Cluster Relationships

```
Hub Lab Cluster
├── Manages Lab Cluster
├── Enforces Policies
├── Monitors Health
└── Coordinates Updates
```

## 🤝 Contributing

### Development Workflow

1. **Create Feature Branch**:
   ```bash
   git checkout -b feature/new-cluster
   ```

2. **Make Changes**:
   - Add new cluster configurations
   - Modify existing clusters
   - Update capabilities

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

- **Consistent Structure**: Follow established directory structure
- **Documentation**: Include README.md for new clusters
- **Testing**: Add tests for new functionality
- **Naming**: Use descriptive, consistent naming conventions

## 📄 License

This project is part of the ODFL OpenShift vSphere IPI Installation automation framework.

---

**Note**: Always test cluster changes in a development environment before deploying to production. Consider the impact of changes on cluster relationships and dependencies.