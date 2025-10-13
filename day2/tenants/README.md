# Tenants - Multi-Tenant Configurations

This directory contains multi-tenant configurations for isolated workloads and environments within OpenShift clusters.

## 📋 Table of Contents

- [Overview](#-overview)
- [Directory Structure](#-directory-structure)
- [Tenant Types](#-tenant-types)
- [Configuration Management](#️-configuration-management)
- [Usage Examples](#-usage-examples)
- [Testing](#-testing)
- [Customization](#-customization)
- [Troubleshooting](#-troubleshooting)
- [Tenant Management](#-tenant-management)
- [Contributing](#-contributing)
- [License](#-license)

## 🎯 Overview

The tenants directory provides multi-tenant configurations that enable:

- **Resource Isolation**: Separate tenant workloads and resources
- **Namespace Management**: Organized namespace structures per tenant
- **RBAC Configuration**: Tenant-specific access controls
- **Resource Quotas**: Tenant resource limits and constraints
- **Network Policies**: Tenant network isolation
- **Custom Configurations**: Tenant-specific settings and overrides

## 📁 Directory Structure

```
tenants/
├── README.md                           # This file
├── clusters/                          # Tenant cluster configurations
│   ├── example-tenant/                # Example tenant configuration
│   │   ├── kustomization.yaml
│   │   └── tenant-config.yaml
│   └── lab/                           # Lab tenant configuration
│       └── README.md                  # Lab tenant documentation
└── tests/                             # Tenant validation tests
    └── test-tenant-configurations.yaml
```

## 🏢 Tenant Types

### 1. Example Tenant (`example-tenant/`)

**Purpose**: Template and example configuration for new tenants

**Features:**
- **Namespace Structure**: Organized namespace hierarchy
- **RBAC Configuration**: Role-based access control
- **Resource Quotas**: Resource limits and constraints
- **Network Policies**: Network isolation rules
- **Custom Configurations**: Tenant-specific settings

**Configuration:**
```yaml
# tenant-config.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: tenant-example
  labels:
    tenant: example
    environment: development
---
apiVersion: v1
kind: ResourceQuota
metadata:
  name: tenant-example-quota
  namespace: tenant-example
spec:
  hard:
    requests.cpu: "2"
    requests.memory: 4Gi
    limits.cpu: "4"
    limits.memory: 8Gi
```

### 2. Lab Tenant (`lab/`)

**Purpose**: Lab environment tenant configuration

**Features:**
- **Development Environment**: Lab-specific configurations
- **Testing Tools**: Development and testing utilities
- **Resource Management**: Lab resource allocation
- **Access Controls**: Lab-specific permissions

**Configuration:**
```yaml
# lab tenant configuration
apiVersion: v1
kind: Namespace
metadata:
  name: tenant-lab
  labels:
    tenant: lab
    environment: development
    purpose: testing
```

## ⚙️ Configuration Management

### Kustomize Structure

Each tenant follows a consistent Kustomize structure:

```yaml
# Example: clusters/example-tenant/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- tenant-config.yaml
- rbac-config.yaml
- network-policies.yaml

patchesStrategicMerge:
- patches/resource-quota-patch.yaml

labels:
- includeSelectors: false
  pairs:
    app.kubernetes.io/part-of: platform-management
    tenant: example-tenant
```

### Tenant Components

Each tenant includes standard components:

**Core Components:**
- **Namespace**: Tenant namespace with proper labeling
- **RBAC**: Role and RoleBinding configurations
- **Resource Quotas**: Resource limits and constraints
- **Network Policies**: Network isolation rules
- **Service Accounts**: Tenant-specific service accounts

**Optional Components:**
- **ConfigMaps**: Tenant-specific configurations
- **Secrets**: Tenant-specific secrets
- **Custom Resources**: Tenant-specific custom resources
- **Monitoring**: Tenant-specific monitoring configuration

### Tenant Labeling

Consistent labeling across all tenant resources:

```yaml
labels:
  app.kubernetes.io/part-of: platform-management
  tenant: "{{ tenant-name }}"
  environment: "{{ environment-type }}"
  purpose: "{{ tenant-purpose }}"
```

## 🚀 Usage Examples

### 1. Deploy Example Tenant

```bash
# Deploy example tenant configuration
kustomize build clusters/example-tenant/ | oc apply -f -

# Verify tenant deployment
oc get namespaces -l tenant=example
oc get resourcequota -n tenant-example
oc get roles -n tenant-example
```

### 2. Deploy Lab Tenant

```bash
# Deploy lab tenant configuration
kustomize build clusters/lab/ | oc apply -f -

# Verify lab tenant deployment
oc get namespaces -l tenant=lab
oc get resourcequota -n tenant-lab
```

### 3. Create New Tenant

```bash
# Create new tenant directory
mkdir clusters/new-tenant
cd clusters/new-tenant

# Create tenant configuration
cat > tenant-config.yaml << EOF
apiVersion: v1
kind: Namespace
metadata:
  name: tenant-new
  labels:
    tenant: new
    environment: production
---
apiVersion: v1
kind: ResourceQuota
metadata:
  name: tenant-new-quota
  namespace: tenant-new
spec:
  hard:
    requests.cpu: "4"
    requests.memory: 8Gi
    limits.cpu: "8"
    limits.memory: 16Gi
EOF

# Create kustomization
cat > kustomization.yaml << EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- tenant-config.yaml

labels:
- includeSelectors: false
  pairs:
    app.kubernetes.io/part-of: platform-management
    tenant: new-tenant
EOF

# Deploy new tenant
kustomize build . | oc apply -f -
```

### 4. Customize Tenant Configuration

```bash
# Apply custom patches
kustomize build clusters/example-tenant/ --enable-patches | oc apply -f -

# Override specific values
kustomize build clusters/example-tenant/ --enable-helm | oc apply -f -
```

## 🧪 Testing

### Automated Validation

The tenants directory includes comprehensive testing:

```bash
# Test all tenant configurations
ansible-playbook tests/test-tenant-configurations.yaml

# Test specific tenant
kustomize build clusters/example-tenant/

# Test with validation
kustomize build clusters/lab/ | oc apply --dry-run=client -f -
```

### Test Coverage

- **Kustomize Build Validation**: Ensures all tenant configurations build successfully
- **Resource Validation**: Checks for proper Kubernetes resource definitions
- **RBAC Validation**: Verifies role and binding configurations
- **Quota Validation**: Ensures resource quotas are properly configured

## 🔧 Customization

### Adding New Tenants

1. **Create Tenant Directory**:
   ```bash
   mkdir clusters/new-tenant
   cd clusters/new-tenant
   ```

2. **Create Tenant Configuration**:
   ```yaml
   # tenant-config.yaml
   apiVersion: v1
   kind: Namespace
   metadata:
     name: tenant-new
     labels:
       tenant: new
       environment: production
   ```

3. **Create Kustomization**:
   ```yaml
   # kustomization.yaml
   apiVersion: kustomize.config.k8s.io/v1beta1
   kind: Kustomization
   
   resources:
   - tenant-config.yaml
   
   labels:
   - includeSelectors: false
     pairs:
       app.kubernetes.io/part-of: platform-management
       tenant: new-tenant
   ```

4. **Add Additional Components**:
   ```bash
   # Add RBAC configuration
   cat > rbac-config.yaml << EOF
   apiVersion: rbac.authorization.k8s.io/v1
   kind: Role
   metadata:
     name: tenant-admin
     namespace: tenant-new
   rules:
   - apiGroups: [""]
     resources: ["pods", "services", "configmaps"]
     verbs: ["get", "list", "create", "update", "delete"]
   EOF
   ```

5. **Test Configuration**:
   ```bash
   kustomize build clusters/new-tenant/
   ```

### Modifying Existing Tenants

1. **Edit Tenant Configuration**:
   ```bash
   vim clusters/existing-tenant/tenant-config.yaml
   ```

2. **Add or Remove Components**:
   ```yaml
   resources:
   - tenant-config.yaml
   - new-component.yaml
   # - removed-component.yaml  # Comment out to remove
   ```

3. **Test Changes**:
   ```bash
   kustomize build clusters/existing-tenant/
   ```

### Tenant-Specific Customizations

1. **Resource Quotas**:
   ```yaml
   # Customize resource limits
   apiVersion: v1
   kind: ResourceQuota
   metadata:
     name: tenant-custom-quota
     namespace: tenant-custom
   spec:
     hard:
       requests.cpu: "8"
       requests.memory: 16Gi
       limits.cpu: "16"
       limits.memory: 32Gi
   ```

2. **Network Policies**:
   ```yaml
   # Customize network isolation
   apiVersion: networking.k8s.io/v1
   kind: NetworkPolicy
   metadata:
     name: tenant-isolation
     namespace: tenant-custom
   spec:
     podSelector: {}
     policyTypes:
     - Ingress
     - Egress
   ```

3. **RBAC Configuration**:
   ```yaml
   # Customize access controls
   apiVersion: rbac.authorization.k8s.io/v1
   kind: Role
   metadata:
     name: tenant-custom-role
     namespace: tenant-custom
   rules:
   - apiGroups: [""]
     resources: ["pods", "services"]
     verbs: ["get", "list", "create", "update", "delete"]
   ```

## 🚨 Troubleshooting

### Common Issues

1. **Tenant Build Failures**
   ```bash
   # Check for missing resources
   kustomize build clusters/tenant-name/
   
   # Verify resource references
   grep -r "kind:" clusters/tenant-name/
   ```

2. **RBAC Issues**
   ```bash
   # Check role bindings
   oc get rolebindings -n tenant-namespace
   
   # Verify permissions
   oc auth can-i create pods --as=system:serviceaccount:tenant-namespace:tenant-sa
   ```

3. **Resource Quota Issues**
   ```bash
   # Check quota status
   oc get resourcequota -n tenant-namespace
   
   # Check quota usage
   oc describe resourcequota tenant-quota -n tenant-namespace
   ```

### Debug Mode

Enable debug mode for detailed troubleshooting:

```bash
# Kustomize debug
kustomize build clusters/tenant-name/ --enable-patches

# Resource validation
kustomize build clusters/tenant-name/ | oc apply --dry-run=client -f -
```

## 📊 Tenant Management

### Tenant Lifecycle

1. **Creation**: Deploy tenant configuration
2. **Configuration**: Set up RBAC, quotas, and policies
3. **Monitoring**: Monitor resource usage and compliance
4. **Updates**: Apply configuration changes
5. **Deletion**: Clean up tenant resources

### Tenant Isolation

- **Namespace Isolation**: Each tenant has dedicated namespaces
- **Resource Isolation**: Resource quotas prevent resource conflicts
- **Network Isolation**: Network policies control traffic flow
- **RBAC Isolation**: Role-based access controls

### Tenant Monitoring

- **Resource Usage**: Monitor CPU, memory, and storage usage
- **Quota Compliance**: Track quota utilization
- **Access Patterns**: Monitor user access and permissions
- **Performance Metrics**: Track tenant performance

## 🤝 Contributing

### Development Workflow

1. **Create Feature Branch**:
   ```bash
   git checkout -b feature/new-tenant
   ```

2. **Make Changes**:
   - Add new tenant configurations
   - Modify existing tenants
   - Update documentation

3. **Test Changes**:
   ```bash
   # Run validation tests
   ansible-playbook tests/test-tenant-configurations.yaml
   ```

4. **Create Pull Request**:
   - Include description of changes
   - Reference any related issues
   - Ensure all tests pass

### Code Standards

- **Consistent Structure**: Follow established directory structure
- **Documentation**: Include README.md for new tenants
- **Testing**: Add tests for new functionality
- **Naming**: Use descriptive, consistent naming conventions

## 📄 License

This project is part of the ODFL OpenShift vSphere IPI Installation automation framework.

---

**Note**: Always test tenant changes in a development environment before deploying to production. Consider the impact of changes on tenant isolation and resource allocation.