# Application Set Helm Chart

This Helm chart contains the resources used to create and manage ArgoCD ApplicationSets for automated cluster discovery and configuration deployment.

## 📋 Table of Contents

- [Overview](#-overview)
- [Chart Structure](#-chart-structure)
- [Configuration](#️-configuration)
- [Usage Examples](#-usage-examples)
- [Troubleshooting](#-troubleshooting)
- [Contributing](#-contributing)
- [License](#-license)

## 🎯 Overview

The Application Set Helm chart provides:

- **Automated Cluster Discovery**: Dynamic cluster detection and configuration
- **ApplicationSet Management**: ArgoCD ApplicationSet resource creation
- **Multi-Environment Support**: Support for different cluster types and environments
- **Configurable Sync Policies**: Flexible synchronization options

## 📁 Chart Structure

```
application-set/
├── Chart.yaml                           # Chart metadata
├── values.yaml                          # Default values
└── templates/
    └── ApplicationSet.yaml              # ApplicationSet template
```

## ⚙️ Configuration

### Chart Values

```yaml
# values.yaml
applicationSetDefaults:
  componentLabel: "platform-management"
  partOfLabel: "platform-management"
  argoCDProject: "platform-management"
  syncPolicyAutomated: true
  syncPolicyPrune: true
  syncPolicySelfHeal: true
  syncOptions:
    - "CreateNamespace=true"
    - "PrunePropagationPolicy=foreground"
    - "PruneLast=true"
  
generators:
  - type: "clusters"
    clusters:
      selector:
        matchLabels:
          cluster-type: "workload"
      template:
        metadata:
          name: "{{name}}-capabilities"
        spec:
          project: "{{values.argoCDProject}}"
          source:
            repoURL: "{{values.repoURL}}"
            targetRevision: "{{values.targetRevision}}"
            path: "{{values.path}}"
          destination:
            server: "{{server}}"
            namespace: "{{values.namespace}}"
          syncPolicy:
            automated:
              prune: "{{values.syncPolicyPrune}}"
              selfHeal: "{{values.syncPolicySelfHeal}}"
            syncOptions: "{{values.syncOptions}}"
  
labels:
  app.kubernetes.io/part-of: "{{values.partOfLabel}}"
  app.kubernetes.io/component: "{{values.componentLabel}}"
  
annotations:
  argocd.argoproj.io/sync-wave: "1"
```

### Customization

**ApplicationSet Configuration:**
```yaml
applicationSetDefaults:
  componentLabel: "custom-management"
  partOfLabel: "custom-management"
  argoCDProject: "custom-management"
  syncPolicyAutomated: true
  syncPolicyPrune: true
  syncPolicySelfHeal: true
  syncOptions:
    - "CreateNamespace=true"
    - "PrunePropagationPolicy=foreground"
    - "PruneLast=true"
    - "RespectIgnoreDifferences=true"
```

**Generator Configuration:**
```yaml
generators:
  - type: "clusters"
    clusters:
      selector:
        matchLabels:
          cluster-type: "workload"
          environment: "production"
      template:
        metadata:
          name: "{{name}}-production-capabilities"
        spec:
          project: "production-management"
          source:
            repoURL: "https://github.com/org/production-repo"
            targetRevision: "main"
            path: "clusters/{{name}}/capabilities"
```

## 🚀 Usage Examples

### 1. Install Chart

```bash
# Install with default values
helm install application-set ./charts/application-set/ \
  --namespace openshift-gitops \
  --create-namespace

# Install with custom values
helm install application-set ./charts/application-set/ \
  --namespace openshift-gitops \
  --values custom-values.yaml
```

### 2. Upgrade Chart

```bash
# Upgrade with new values
helm upgrade application-set ./charts/application-set/ \
  --namespace openshift-gitops \
  --values updated-values.yaml

# Upgrade with specific values
helm upgrade application-set ./charts/application-set/ \
  --namespace openshift-gitops \
  --set applicationSetDefaults.argoCDProject=custom-management
```

### 3. Uninstall Chart

```bash
# Uninstall chart
helm uninstall application-set \
  --namespace openshift-gitops
```

### 4. Template Chart

```bash
# Generate templates
helm template application-set ./charts/application-set/ \
  --values custom-values.yaml

# Generate templates with debug
helm template application-set ./charts/application-set/ \
  --values custom-values.yaml \
  --debug
```

## 🚨 Troubleshooting

### Common Issues

1. **ApplicationSet Not Creating Applications**
   ```bash
   # Check ApplicationSet status
   oc get applicationset -n openshift-gitops
   
   # Check ApplicationSet details
   oc describe applicationset cluster-management-gitops -n openshift-gitops
   
   # Check ApplicationSet logs
   oc logs -n openshift-gitops deployment/argocd-applicationset-controller
   ```

2. **Cluster Discovery Issues**
   ```bash
   # Check managed clusters
   oc get managedclusters
   
   # Check cluster labels
   oc get managedclusters -o yaml | grep -A 5 -B 5 "cluster-type"
   
   # Check cluster secrets
   oc get secrets -n open-cluster-management
   ```

3. **Application Creation Failed**
   ```bash
   # Check applications
   oc get applications -n openshift-gitops
   
   # Check application details
   oc describe application cluster-name-capabilities -n openshift-gitops
   
   # Check application logs
   oc logs -n openshift-gitops deployment/argocd-application-controller
   ```

4. **Sync Policy Issues**
   ```bash
   # Check sync status
   oc get applications -n openshift-gitops -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.sync.status}{"\n"}{end}'
   
   # Check sync conditions
   oc get applications -n openshift-gitops -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.conditions[*].message}{"\n"}{end}'
   ```

### Debug Mode

Enable debug mode for detailed troubleshooting:

```bash
# Helm debug
helm template application-set ./charts/application-set/ \
  --values custom-values.yaml \
  --debug

# ApplicationSet debug
oc patch applicationset cluster-management-gitops -n openshift-gitops --type merge -p '{"spec":{"template":{"spec":{"syncPolicy":{"syncOptions":["CreateNamespace=true"]}}}}}'

# Application debug
oc patch application cluster-name-capabilities -n openshift-gitops --type merge -p '{"spec":{"syncPolicy":{"syncOptions":["CreateNamespace=true"]}}}'
```

### Log Analysis

```bash
# Check ApplicationSet controller logs
oc logs -n openshift-gitops deployment/argocd-applicationset-controller

# Check application controller logs
oc logs -n openshift-gitops deployment/argocd-application-controller

# Check ArgoCD server logs
oc logs -n openshift-gitops deployment/argocd-server
```

## 🤝 Contributing

### Development Workflow

1. **Create Feature Branch**:
   ```bash
   git checkout -b feature/application-set-update
   ```

2. **Make Changes**:
   - Update chart templates
   - Modify values.yaml
   - Update documentation

3. **Test Changes**:
   ```bash
   # Test chart template
   helm template application-set ./charts/application-set/
   
   # Test chart lint
   helm lint ./charts/application-set/
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

**Note**: Always test chart changes in a development environment before deploying to production. Consider the impact of changes on cluster discovery and application deployment.