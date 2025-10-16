# Init - Foundation Setup

This kustomization initializes the GitOps feedback loop between Red Hat OpenShift GitOps (ArgoCD) and Red Hat Advanced Cluster Management for Kubernetes (Open Cluster Management) on the labhub cluster.

## 📋 Table of Contents

- [Overview](#-overview)
- [Prerequisites](#-prerequisites)
- [Directory Structure](#-directory-structure)
- [Configuration Components](#-configuration-components)
- [Usage Examples](#-usage-examples)
- [Troubleshooting](#-troubleshooting)
- [Contributing](#-contributing)
- [License](#-license)

## 🎯 Overview

The init foundation setup provides:

- **GitOps Integration**: Establishes ArgoCD and ACM integration
- **Application Deployment**: Deploys essential applications via ArgoCD
- **Policy Management**: Configures ACM policies for cluster management
- **Feedback Loop**: Creates bidirectional communication between ArgoCD and ACM

## 📋 Prerequisites

- **OpenShift GitOps Operator**: Must be installed and available
- **ACM Operator**: Advanced Cluster Management operator installed
- **Cluster Access**: Proper RBAC permissions for deployment
- **Git Repository**: Access to GitOps repository

## 📁 Directory Structure

```
.init/
├── README.md                           # This file
├── kustomization.yaml                  # Main kustomization
├── applications/                       # ArgoCD applications
│   ├── gitops-app.yaml
│   └── acm-app.yaml
├── policies/                           # ACM policies
│   ├── gitops-policy.yaml
│   └── cluster-policy.yaml
└── placement-rules/                    # Policy placement rules
    ├── gitops-placement.yaml
    └── cluster-placement.yaml
```

## 🔧 Configuration Components

### 1. ArgoCD Applications

**Purpose**: Deploy essential applications via GitOps

**Applications:**
- GitOps repository configuration
- ACM integration applications
- Cluster management applications

**Configuration:**
```yaml
# applications/gitops-app.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: gitops-foundation
  namespace: openshift-gitops
spec:
  project: "default"
  source:
    repoURL: "https://github.com/org/gitops-repo"
    targetRevision: "HEAD"
    path: "clusters/labhub"
  destination:
    server: "https://kubernetes.default.svc"
    namespace: "openshift-gitops"
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

### 2. ACM Policies

**Purpose**: Configure cluster management policies

**Policies:**
- GitOps repository policies
- Cluster configuration policies
- Compliance monitoring policies

**Configuration:**
```yaml
# policies/gitops-policy.yaml
apiVersion: policy.open-cluster-management.io/v1
kind: Policy
metadata:
  name: gitops-foundation-policy
  namespace: open-cluster-management
spec:
  remediationAction: enforce
  disabled: false
  policy-templates:
  - objectDefinition:
      apiVersion: policy.open-cluster-management.io/v1
      kind: ConfigurationPolicy
      metadata:
        name: gitops-foundation-config
      spec:
        remediationAction: enforce
        severity: high
        object-templates:
        - complianceType: musthave
          objectDefinition:
            apiVersion: v1
            kind: ConfigMap
            metadata:
              name: gitops-foundation-config
              namespace: openshift-gitops
```

### 3. Placement Rules

**Purpose**: Define policy placement and application targeting

**Configuration:**
```yaml
# placement-rules/gitops-placement.yaml
apiVersion: apps.open-cluster-management.io/v1
kind: PlacementRule
metadata:
  name: gitops-foundation-placement
  namespace: open-cluster-management
spec:
  clusterSelector:
    matchLabels:
      cluster-type: "hub"
      environment: "lab"
```

## 🚀 Usage Examples

### 1. Initialize Foundation

```bash
# Deploy foundation configuration
kustomize build .init/labhub/ | oc apply -f -

# Verify deployment
oc get applications -n openshift-gitops
oc get policies -A
```

### 2. Use with Ansible Playbook

```bash
# Run initialization playbook
ansible-playbook ansible/init_gitops.yaml

# Verify playbook execution
oc get applications -n openshift-gitops
oc get policies -A
```

### 3. Customize Configuration

```bash
# Apply custom patches
kustomize build .init/labhub/ --enable-patches | oc apply -f -

# Override specific values
kustomize build .init/labhub/ --enable-helm | oc apply -f -
```

### 4. Verify GitOps Loop

```bash
# Check ArgoCD applications
oc get applications -n openshift-gitops

# Check ACM policies
oc get policies -A

# Check policy compliance
oc describe policy gitops-foundation-policy -n open-cluster-management
```

## 🚨 Troubleshooting

### Common Issues

1. **GitOps Operator Not Available**
   ```bash
   # Check GitOps operator status
   oc get pods -n openshift-gitops
   
   # Check operator subscription
   oc get subscription -n openshift-gitops
   
   # Check operator logs
   oc logs -n openshift-gitops deployment/openshift-gitops-operator
   ```

2. **ACM Integration Issues**
   ```bash
   # Check ACM operator status
   oc get pods -n open-cluster-management
   
   # Check ACM hub status
   oc get multiclusterhub -A
   
   # Check ACM logs
   oc logs -n open-cluster-management deployment/multicluster-observability-operator
   ```

3. **Application Deployment Failed**
   ```bash
   # Check application status
   oc get applications -n openshift-gitops
   
   # Check application details
   oc describe application gitops-foundation -n openshift-gitops
   
   # Check application logs
   oc logs -n openshift-gitops deployment/argocd-application-controller
   ```

4. **Policy Compliance Issues**
   ```bash
   # Check policy status
   oc get policies -A
   
   # Check policy violations
   oc get policyviolations -A
   
   # Check compliance status
   oc get policies -A -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.complianceState}{"\n"}{end}'
   ```

### Debug Mode

Enable debug mode for detailed troubleshooting:

```bash
# Kustomize debug
kustomize build .init/labhub/ --enable-helm --enable-alpha-plugins

# Application debug
oc patch application gitops-foundation -n openshift-gitops --type merge -p '{"spec":{"syncPolicy":{"syncOptions":["CreateNamespace=true"]}}}'

# Policy debug
oc patch policy gitops-foundation-policy -n open-cluster-management --type merge -p '{"spec":{"disabled":false}}'
```

### Log Analysis

```bash
# Check GitOps logs
oc logs -n openshift-gitops deployment/argocd-server
oc logs -n openshift-gitops deployment/argocd-application-controller

# Check ACM logs
oc logs -n open-cluster-management deployment/multicluster-observability-operator
oc logs -n open-cluster-management deployment/governance-policy-framework

# Check foundation logs
oc logs -n openshift-gitops deployment/gitops-foundation
```

## 🤝 Contributing

### Development Workflow

1. **Create Feature Branch**:
   ```bash
   git checkout -b feature/init-foundation-update
   ```

2. **Make Changes**:
   - Update foundation configuration
   - Modify applications or policies
   - Update documentation

3. **Test Changes**:
   ```bash
   # Test foundation build
   kustomize build .init/labhub/
   
   # Test with playbook
   ansible-playbook ansible/init_gitops.yaml
   ```

4. **Create Pull Request**:
   - Include description of changes
   - Reference any related issues
   - Ensure all tests pass

### Code Standards

- **Consistent Structure**: Follow established directory structure
- **Documentation**: Include README.md for new components
- **Testing**: Add tests for new functionality
- **Naming**: Use descriptive, consistent naming conventions

## 📄 License

This project is part of the ODFL OpenShift vSphere IPI Installation automation framework.

---

**Note**: Always test foundation changes in a development environment before deploying to production. Consider the impact of changes on the GitOps feedback loop and cluster management.
