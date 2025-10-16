# Cluster Groups - Logical Cluster Groupings

This directory contains logical groupings of clusters with shared capabilities, managed through Kustomize and ArgoCD ApplicationSets.

## 📋 Table of Contents

- [Overview](#-overview)
- [Directory Structure](#-directory-structure)
- [Group Types](#-group-types)
- [Configuration Management](#️-configuration-management)
- [Usage Examples](#-usage-examples)
- [Testing](#-testing)
- [Customization](#-customization)
- [Troubleshooting](#-troubleshooting)
- [Group Management](#-group-management)
- [Contributing](#-contributing)
- [License](#-license)

## 🎯 Overview

Cluster groups provide a way to logically organize clusters and apply shared capabilities across multiple clusters. This approach enables:

- **Consistent Configuration**: Apply the same capabilities to all clusters in a group
- **Environment Management**: Separate configurations for different environments
- **Protection Levels**: Control which capabilities are protected from deletion
- **Scalable Management**: Easily add new clusters to existing groups

## 📁 Directory Structure

```
groups/
├── README.md                           # This file
├── kustomize/                         # Kustomize group configurations
│   └── groups/
│       ├── all/                       # All clusters group
│       │   └── capabilities/
│       │       ├── identity-configuration/     # Identity provider config
│       │       └── external-secrets-operator/  # External Secrets Operator
│       ├── dev-protected/             # Protected development clusters
│       │   └── capabilities/
│       │       └── storage/           # Storage management
│       ├── hub-lab/                   # Hub lab cluster group
│       │   └── capabilities/
│       │       └── acm-policies-openshift-gitops/  # ACM policies
│       ├── hub-lab-protected/         # Protected hub lab group
│       │   └── capabilities/
│       │       ├── acm-hub/           # ACM hub configuration
│       │       └── acm-operator/      # ACM operator
│       └── lab/                       # Lab cluster group
│           └── capabilities/
│               └── web-console-cluster-customization/  # Console customization
└── tests/                             # Group validation tests
    └── test-all-kustomization-builds-playbook.yaml
```

## 🏷️ Group Types

### 1. All Clusters (`all/`)

**Purpose**: Capabilities applied to all clusters regardless of type or environment

**Capabilities:**
- Identity configuration
- External Secrets Operator
- Common security policies
- Base monitoring setup

**Usage:**
```yaml
# Apply to all clusters
kustomize build kustomize/groups/all/
```

### 2. Hub Lab (`hub-lab/`)

**Purpose**: Hub cluster specific capabilities for managing workload clusters

**Capabilities:**
- ACM policies for OpenShift GitOps
- Multi-cluster management
- Hub-specific monitoring
- Centralized logging

**Usage:**
```yaml
# Apply to hub clusters
kustomize build kustomize/groups/hub-lab/
```

### 3. Hub Lab Protected (`hub-lab-protected/`)

**Purpose**: Critical hub capabilities that must be protected from deletion

**Capabilities:**
- ACM hub configuration
- ACM operator
- Core management components
- Essential monitoring

**Protection Level**: High - prevents cascade deletion

**Usage:**
```yaml
# Apply protected hub capabilities
kustomize build kustomize/groups/hub-lab-protected/
```

### 4. Development Protected (`dev-protected/`)

**Purpose**: Development cluster capabilities with protection

**Capabilities:**
- Storage management
- Development tools
- Testing frameworks
- Debug utilities

**Protection Level**: Medium - protects development resources

**Usage:**
```yaml
# Apply to development clusters
kustomize build kustomize/groups/dev-protected/
```

### 5. Lab (`lab/`)

**Purpose**: Lab cluster specific capabilities

**Capabilities:**
- Web console customization
- Lab-specific tools
- Testing configurations
- Development environments

**Usage:**
```yaml
# Apply to lab clusters
kustomize build kustomize/groups/lab/
```

## ⚙️ Configuration Management

### Kustomize Structure

Each group follows a consistent Kustomize structure:

```yaml
# Example: groups/hub-lab/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- capabilities/acm-policies-openshift-gitops/

patchesStrategicMerge:
- patches/namespace-patch.yaml

labels:
- includeSelectors: false
  pairs:
    app.kubernetes.io/part-of: platform-management
    cluster-group: hub-lab
```

### Group Labels

Groups use consistent labeling for identification:

```yaml
labels:
- includeSelectors: false
  pairs:
    app.kubernetes.io/part-of: platform-management
    cluster-group: "{{ group-name }}"
    environment: "{{ environment-type }}"
    protection-level: "{{ protection-level }}"
```

### Capability Organization

Capabilities are organized by function and scope:

```
capabilities/
├── identity-configuration/          # Identity and authentication
├── external-secrets-operator/       # Secret management
├── acm-policies-openshift-gitops/   # ACM policies
├── storage/                         # Storage management
├── acm-hub/                         # ACM hub configuration
└── web-console-cluster-customization/  # Console customization
```

## 🚀 Usage Examples

### 1. Deploy All Cluster Capabilities

```bash
# Deploy capabilities to all clusters
kustomize build kustomize/groups/all/ | oc apply -f -

# Verify deployment
oc get applications -n openshift-gitops
```

### 2. Deploy Hub Cluster Capabilities

```bash
# Deploy hub-specific capabilities
kustomize build kustomize/groups/hub-lab/ | oc apply -f -

# Deploy protected hub capabilities
kustomize build kustomize/groups/hub-lab-protected/ | oc apply -f -
```

### 3. Deploy Development Cluster Capabilities

```bash
# Deploy development capabilities
kustomize build kustomize/groups/dev-protected/ | oc apply -f -

# Verify protection
oc get applications -n openshift-gitops -l protection-level=medium
```

### 4. Deploy Lab Cluster Capabilities

```bash
# Deploy lab-specific capabilities
kustomize build kustomize/groups/lab/ | oc apply -f -

# Verify console customization
oc get consolelink
```

## 🧪 Testing

### Automated Validation

The cluster groups include comprehensive testing:

```bash
# Test all group configurations
ansible-playbook tests/test-all-kustomization-builds-playbook.yaml

# Test specific group
kustomize build kustomize/groups/hub-lab/

# Test with validation
kustomize build kustomize/groups/all/ | oc apply --dry-run=client -f -
```

### Test Coverage

- **Kustomize Build Validation**: Ensures all group configurations build successfully
- **Resource Validation**: Checks for proper Kubernetes resource definitions
- **Label Validation**: Verifies consistent labeling across groups
- **Dependency Validation**: Ensures all dependencies are satisfied

## 🔧 Customization

### Adding New Groups

1. **Create Group Directory**:
   ```bash
   mkdir kustomize/groups/new-group
   cd kustomize/groups/new-group
   ```

2. **Create Kustomization**:
   ```yaml
   # kustomization.yaml
   apiVersion: kustomize.config.k8s.io/v1beta1
   kind: Kustomization
   
   resources:
   - capabilities/capability-name/
   
   labels:
   - includeSelectors: false
     pairs:
       app.kubernetes.io/part-of: platform-management
       cluster-group: new-group
   ```

3. **Add Capabilities**:
   ```bash
   mkdir capabilities
   # Add capability configurations
   ```

4. **Test Configuration**:
   ```bash
   kustomize build kustomize/groups/new-group/
   ```

### Modifying Existing Groups

1. **Edit Group Configuration**:
   ```bash
   vim kustomize/groups/existing-group/kustomization.yaml
   ```

2. **Add or Remove Capabilities**:
   ```yaml
   resources:
   - capabilities/new-capability/
   # - capabilities/removed-capability/  # Comment out to remove
   ```

3. **Test Changes**:
   ```bash
   kustomize build kustomize/groups/existing-group/
   ```

### Adding New Capabilities

1. **Create Capability Directory**:
   ```bash
   mkdir kustomize/groups/group-name/capabilities/new-capability
   cd kustomize/groups/group-name/capabilities/new-capability
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

3. **Update Group Kustomization**:
   ```yaml
   # Add to group kustomization.yaml
   resources:
   - capabilities/new-capability/
   ```

## 🚨 Troubleshooting

### Common Issues

1. **Group Build Failures**
   ```bash
   # Check for missing capabilities
   kustomize build kustomize/groups/group-name/
   
   # Verify capability references
   grep -r "capabilities/" kustomize/groups/group-name/
   ```

2. **Label Conflicts**
   ```bash
   # Check for duplicate labels
   oc get applications -A -o yaml | grep -A 5 -B 5 "cluster-group"
   
   # Verify label consistency
   kustomize build kustomize/groups/group-name/ | grep -A 10 "labels:"
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
kustomize build --enable-helm --enable-alpha-plugins kustomize/groups/group-name/

# Resource validation
kustomize build kustomize/groups/group-name/ | oc apply --dry-run=client -f -
```

## 📊 Group Management

### Group Hierarchy

```
All Clusters
├── Hub Lab (Hub clusters)
│   └── Hub Lab Protected (Critical hub components)
├── Lab (Workload clusters)
└── Dev Protected (Development clusters)
```

### Protection Levels

- **High**: Critical components that must never be deleted
- **Medium**: Important components with controlled deletion
- **Low**: Standard components that can be safely deleted

### Environment Mapping

- **Production**: Hub Lab + Hub Lab Protected
- **Development**: Dev Protected
- **Testing**: Lab
- **All**: Identity, Security, Monitoring

## 🤝 Contributing

### Development Workflow

1. **Create Feature Branch**:
   ```bash
   git checkout -b feature/new-group
   ```

2. **Make Changes**:
   - Add new group configurations
   - Modify existing groups
   - Update documentation

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

- **Consistent Labeling**: Use standard label patterns
- **Documentation**: Include README.md for new groups
- **Testing**: Add tests for new functionality
- **Naming**: Use descriptive, consistent naming conventions

## 📄 License

This project is part of the ODFL OpenShift vSphere IPI Installation automation framework.

---

**Note**: Always test group changes in a development environment before deploying to production clusters. Consider the impact of changes on cluster protection levels.