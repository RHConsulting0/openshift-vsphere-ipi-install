# Compute GitOps Helm Chart

This Helm chart contains the resources used to create and configure GitOps instances on compute clusters. It creates an ArgoCD instance, AppProject, and necessary RBAC configurations for GitOps operations.

## 📋 Table of Contents

- [Overview](#-overview)
- [Chart Structure](#-chart-structure)
- [Configuration](#️-configuration)
- [Usage Examples](#-usage-examples)
- [Troubleshooting](#-troubleshooting)
- [Contributing](#-contributing)
- [License](#-license)

## 🎯 Overview

The Compute GitOps Helm chart provides:

- **ArgoCD Instance**: GitOps instance for compute clusters
- **AppProject Management**: Project-based access control
- **RBAC Configuration**: Service account and role bindings
- **Console Integration**: Console link for easy access

## 📁 Chart Structure

```
compute-gitops/
├── Chart.yaml                           # Chart metadata
├── values.yaml                          # Default values
└── templates/
    ├── AppProject_default.yaml          # Default AppProject
    ├── ClusterRole_vpc-admin.yaml       # Admin ClusterRole
    ├── ClusterRoleBinding_vpc-admin.yaml # Admin ClusterRoleBinding
    ├── ArgoCD_vpc-gitops.yaml           # ArgoCD instance
    ├── AppProject_vpc-management.yaml   # Management AppProject
    └── ConsoleLink.yaml                 # Console link
```

## ⚙️ Configuration

### Chart Values

```yaml
# values.yaml
argoCD:
  namespace: "openshift-gitops"
  instance: "vpc-gitops"
  server:
    host: "vpc-gitops-server"
    port: 443
    protocol: "https"
  
appProjects:
  - name: "vpc-management"
    description: "VPC Management Project"
    sourceRepos:
      - "https://github.com/org/repo"
    destinations:
      - namespace: "vpc-management"
        server: "https://kubernetes.default.svc"
  
rbac:
  serviceAccount:
    name: "vpc-gitops"
    namespace: "openshift-gitops"
  clusterRole:
    name: "vpc-admin"
  
consoleLink:
  name: "vpc-gitops"
  href: "https://vpc-gitops-server"
  text: "VPC GitOps"
  location: "ApplicationMenu"
```

### Customization

**ArgoCD Instance Configuration:**
```yaml
argoCD:
  instance: "custom-gitops"
  server:
    host: "custom-gitops-server"
    port: 443
    protocol: "https"
  resources:
    requests:
      cpu: "100m"
      memory: "128Mi"
    limits:
      cpu: "500m"
      memory: "512Mi"
```

**AppProject Configuration:**
```yaml
appProjects:
  - name: "custom-management"
    description: "Custom Management Project"
    sourceRepos:
      - "https://github.com/org/custom-repo"
    destinations:
      - namespace: "custom-management"
        server: "https://kubernetes.default.svc"
    clusterResourceWhitelist:
      - group: ""
        kind: "Namespace"
      - group: "apps"
        kind: "Deployment"
```

## 🚀 Usage Examples

### 1. Install Chart

```bash
# Install with default values
helm install compute-gitops ./charts/compute-gitops/ \
  --namespace openshift-gitops \
  --create-namespace

# Install with custom values
helm install compute-gitops ./charts/compute-gitops/ \
  --namespace openshift-gitops \
  --values custom-values.yaml
```

### 2. Upgrade Chart

```bash
# Upgrade with new values
helm upgrade compute-gitops ./charts/compute-gitops/ \
  --namespace openshift-gitops \
  --values updated-values.yaml

# Upgrade with specific values
helm upgrade compute-gitops ./charts/compute-gitops/ \
  --namespace openshift-gitops \
  --set argoCD.instance=custom-gitops
```

### 3. Uninstall Chart

```bash
# Uninstall chart
helm uninstall compute-gitops \
  --namespace openshift-gitops
```

### 4. Template Chart

```bash
# Generate templates
helm template compute-gitops ./charts/compute-gitops/ \
  --values custom-values.yaml

# Generate templates with debug
helm template compute-gitops ./charts/compute-gitops/ \
  --values custom-values.yaml \
  --debug
```

## 🚨 Troubleshooting

### Common Issues

1. **ArgoCD Instance Not Starting**
   ```bash
   # Check ArgoCD pods
   oc get pods -n openshift-gitops -l app.kubernetes.io/name=argocd
   
   # Check ArgoCD logs
   oc logs -n openshift-gitops deployment/vpc-gitops-server
   
   # Check ArgoCD status
   oc get argocd vpc-gitops -n openshift-gitops
   ```

2. **AppProject Creation Failed**
   ```bash
   # Check AppProject status
   oc get appproject -n openshift-gitops
   
   # Check AppProject details
   oc describe appproject vpc-management -n openshift-gitops
   
   # Check RBAC permissions
   oc auth can-i create appproject --as=system:serviceaccount:openshift-gitops:vpc-gitops
   ```

3. **RBAC Configuration Issues**
   ```bash
   # Check ClusterRole
   oc get clusterrole vpc-admin
   
   # Check ClusterRoleBinding
   oc get clusterrolebinding vpc-admin
   
   # Check ServiceAccount
   oc get serviceaccount vpc-gitops -n openshift-gitops
   ```

4. **Console Link Not Appearing**
   ```bash
   # Check ConsoleLink
   oc get consolelink vpc-gitops
   
   # Check console operator
   oc get pods -n openshift-console
   
   # Check console logs
   oc logs -n openshift-console deployment/console
   ```

### Debug Mode

Enable debug mode for detailed troubleshooting:

```bash
# Helm debug
helm template compute-gitops ./charts/compute-gitops/ \
  --values custom-values.yaml \
  --debug

# ArgoCD debug
oc patch argocd vpc-gitops -n openshift-gitops --type merge -p '{"spec":{"server":{"insecure":true}}}'

# RBAC debug
oc auth can-i create appproject --as=system:serviceaccount:openshift-gitops:vpc-gitops -v 6
```

### Log Analysis

```bash
# Check ArgoCD server logs
oc logs -n openshift-gitops deployment/vpc-gitops-server

# Check ArgoCD application controller logs
oc logs -n openshift-gitops deployment/vpc-gitops-application-controller

# Check ArgoCD repo server logs
oc logs -n openshift-gitops deployment/vpc-gitops-repo-server
```

## 🤝 Contributing

### Development Workflow

1. **Create Feature Branch**:
   ```bash
   git checkout -b feature/compute-gitops-update
   ```

2. **Make Changes**:
   - Update chart templates
   - Modify values.yaml
   - Update documentation

3. **Test Changes**:
   ```bash
   # Test chart template
   helm template compute-gitops ./charts/compute-gitops/
   
   # Test chart lint
   helm lint ./charts/compute-gitops/
   ```

4. **Create Pull Request**:
   - Include description of changes
   - Reference any related issues
   - Ensure all tests pass

### Code Standards

- **Consistent Structure**: Follow established chart structure
- **Documentation**: Include README.md for new charts
- **Testing**: Add tests for new functionality
- **Naming**: Use descriptive, consistent naming conventions

## 📄 License

This project is part of the ODFL OpenShift vSphere IPI Installation automation framework.

---

**Note**: Always test chart changes in a development environment before deploying to production. Consider the impact of changes on GitOps operations and RBAC permissions.