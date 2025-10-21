# ACM Policies OpenShift GitOps

This directory manages Advanced Cluster Management (ACM) policies for OpenShift GitOps configuration across managed clusters.

## 📋 Table of Contents

- [Overview](#-overview)
- [Directory Structure](#-directory-structure)
- [Policy Components](#-policy-components)
- [Configuration Management](#️-configuration-management)
- [Usage Examples](#-usage-examples)
- [Troubleshooting](#-troubleshooting)
- [Contributing](#-contributing)
- [License](#-license)

## 🎯 Overview

The ACM policies OpenShift GitOps capability provides:

- **Policy Enforcement**: Consistent GitOps configuration across clusters
- **Compliance Monitoring**: Automated compliance checking and reporting
- **Automated Remediation**: Self-healing configuration management
- **Multi-Cluster Management**: Centralized policy management

**Note**: There is no `kustomization.yaml` at this level because these capabilities are meant to be loaded by an ArgoCD ApplicationSet.

## 📁 Directory Structure

```
acm-policies-openshift-gitops/
├── README.md                           # This file
├── kustomization.yaml                  # Main kustomization
└── cluster-gitops-repository-configuration/
    ├── kustomization.yaml
    ├── policy.yaml
    └── placement-rule.yaml
```

## 🔧 Policy Components

### 1. Cluster GitOps Repository Configuration

**Purpose**: Ensures consistent GitOps repository configuration across managed clusters

**Policy Features:**
- GitOps repository validation
- ArgoCD configuration enforcement
- Repository access control
- Sync policy standardization

**Configuration:**
```yaml
# cluster-gitops-repository-configuration/policy.yaml
apiVersion: policy.open-cluster-management.io/v1
kind: Policy
metadata:
  name: gitops-repository-configuration
  namespace: open-cluster-management
spec:
  remediationAction: enforce
  disabled: false
  policy-templates:
  - objectDefinition:
      apiVersion: policy.open-cluster-management.io/v1
      kind: ConfigurationPolicy
      metadata:
        name: gitops-repository-config
      spec:
        remediationAction: enforce
        severity: high
        object-templates:
        - complianceType: musthave
          objectDefinition:
            apiVersion: v1
            kind: ConfigMap
            metadata:
              name: gitops-repository-config
              namespace: openshift-gitops
            data:
              repository: "https://github.com/org/gitops-repo"
              branch: "main"
              path: "clusters/{{ .cluster.name }}"
```

### 2. Placement Rule

**Purpose**: Defines which clusters the policy applies to

**Configuration:**
```yaml
# cluster-gitops-repository-configuration/placement-rule.yaml
apiVersion: apps.open-cluster-management.io/v1
kind: PlacementRule
metadata:
  name: gitops-repository-placement
  namespace: open-cluster-management
spec:
  clusterSelector:
    matchLabels:
      cluster-type: "workload"
      environment: "production"
```

## ⚙️ Configuration Management

### ApplicationSet Integration

These policies are deployed via ArgoCD ApplicationSets:

```yaml
# Example ApplicationSet configuration
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: acm-policies-gitops
spec:
  generators:
  - clusters:
      selector:
        matchLabels:
          cluster-type: "hub"
  template:
    metadata:
      name: "{{name}}-acm-policies-gitops"
    spec:
      project: "platform-management"
      source:
        repoURL: "https://github.com/org/repo"
        targetRevision: "HEAD"
        path: "groups/kustomize/groups/hub/capabilities/acm-policies-openshift-gitops"
```

### Policy Dependencies

Policies have specific dependencies:

1. **ACM Hub** → Requires ACM operator and hub configuration
2. **Managed Clusters** → Requires cluster registration
3. **GitOps Repository** → Requires repository access
4. **Placement Rules** → Requires cluster labeling

## 🚀 Usage Examples

### 1. Deploy ACM Policies

```bash
# Deploy via ApplicationSet (recommended)
# The ApplicationSet will automatically deploy all policies

# Manual deployment (for testing)
kustomize build cluster-gitops-repository-configuration/ | oc apply -f -
```

### 2. Verify Policy Compliance

```bash
# Check policy status
oc get policies -A

# Check policy compliance
oc describe policy gitops-repository-configuration -n open-cluster-management

# Check policy violations
oc get policyviolations -A
```

### 3. Update Policy Configuration

```bash
# Update policy configuration
oc patch policy gitops-repository-configuration -n open-cluster-management --type merge -p '{"spec":{"remediationAction":"enforce"}}'

# Verify policy update
oc get policy gitops-repository-configuration -n open-cluster-management -o yaml
```

### 4. Customize Placement Rules

```bash
# Update placement rule
oc patch placementrule gitops-repository-placement -n open-cluster-management --type merge -p '{"spec":{"clusterSelector":{"matchLabels":{"environment":"production"}}}}'

# Verify placement rule
oc get placementrule gitops-repository-placement -n open-cluster-management -o yaml
```

## 🚨 Troubleshooting

### Common Issues

1. **Policy Not Applied**
   ```bash
   # Check policy status
   oc get policies -A
   
   # Check policy details
   oc describe policy gitops-repository-configuration -n open-cluster-management
   
   # Check policy logs
   oc logs -n open-cluster-management deployment/governance-policy-framework
   ```

2. **Placement Rule Issues**
   ```bash
   # Check placement rule status
   oc get placementrule -A
   
   # Check cluster labels
   oc get managedclusters -o yaml | grep -A 5 -B 5 "cluster-type"
   
   # Check placement rule details
   oc describe placementrule gitops-repository-placement -n open-cluster-management
   ```

3. **Policy Violations**
   ```bash
   # Check policy violations
   oc get policyviolations -A
   
   # Check violation details
   oc describe policyviolation violation-name -n open-cluster-management
   
   # Check compliance status
   oc get policies -A -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.complianceState}{"\n"}{end}'
   ```

4. **Remediation Issues**
   ```bash
   # Check remediation status
   oc get policies -A -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.remediationAction}{"\n"}{end}'
   
   # Check remediation logs
   oc logs -n open-cluster-management deployment/governance-policy-framework
   ```

### Debug Mode

Enable debug mode for detailed troubleshooting:

```bash
# Kustomize debug
kustomize build cluster-gitops-repository-configuration/ --enable-helm --enable-alpha-plugins

# Policy debug
oc patch policy gitops-repository-configuration -n open-cluster-management --type merge -p '{"spec":{"disabled":false}}'

# Placement rule debug
oc get placementrule gitops-repository-placement -n open-cluster-management -o yaml
```

### Log Analysis

```bash
# Check ACM policy logs
oc logs -n open-cluster-management deployment/governance-policy-framework

# Check policy controller logs
oc logs -n open-cluster-management deployment/governance-policy-spec-sync

# Check policy status logs
oc logs -n open-cluster-management deployment/governance-policy-status-sync
```

## 🤝 Contributing

### Development Workflow

1. **Create Feature Branch**:
   ```bash
   git checkout -b feature/acm-policies-update
   ```

2. **Make Changes**:
   - Add new policy configurations
   - Modify existing policies
   - Update documentation

3. **Test Changes**:
   ```bash
   # Test policy build
   kustomize build cluster-gitops-repository-configuration/
   
   # Test with ApplicationSet
   oc apply -f applicationset.yaml
   ```

4. **Create Pull Request**:
   - Include description of changes
   - Reference any related issues
   - Ensure all tests pass

### Code Standards

- **Consistent Structure**: Follow established directory structure
- **Documentation**: Include README.md for new policies
- **Testing**: Add tests for new functionality
- **Naming**: Use descriptive, consistent naming conventions

## 📄 License

This project is part of the ODFL OpenShift vSphere IPI Installation automation framework.

---

**Note**: Always test policy changes in a development environment before deploying to production. Consider the impact of changes on managed clusters and compliance requirements.