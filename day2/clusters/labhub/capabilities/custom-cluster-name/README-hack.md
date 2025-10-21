# Custom Cluster Name

This capability provides a workaround for the ACM-1290 issue where the cluster Open Cluster Manager (RHACM) is installed on is always called `local-cluster`, which causes problems when managing multiple RHACM instances.

## 📋 Table of Contents

- [Overview](#-overview)
- [Problem Description](#-problem-description)
- [Solution](#-solution)
- [Configuration](#️-configuration)
- [Usage Examples](#-usage-examples)
- [Troubleshooting](#-troubleshooting)
- [Deprecation Notice](#-deprecation-notice)
- [Contributing](#-contributing)
- [License](#-license)

## 🎯 Overview

The custom cluster name capability provides:

- **Cluster Name Override**: Customizes the default cluster name
- **Multi-ACM Support**: Enables multiple ACM instances management
- **Temporary Workaround**: Addresses ACM-1290 issue
- **Automated Patching**: Applies cluster name patches automatically

## 🚨 Problem Description

### ACM-1290 Issue

**Problem**: As of October 9th, 2024, the cluster where Open Cluster Manager (RHACM) is installed is always named `local-cluster`, regardless of the actual cluster name.

**Impact**:
- Multiple RHACM instances cannot be distinguished
- Cluster management becomes confusing
- Resource conflicts may occur
- Monitoring and logging issues

**Root Cause**: ACM-1290 - Cluster name is hardcoded to `local-cluster`

## 🔧 Solution

### Cluster Name Patching

This capability patches the cluster name to use the actual cluster name instead of the hardcoded `local-cluster`.

**Configuration:**
```yaml
# cluster-name-patch.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: cluster-name-patch
  namespace: open-cluster-management
data:
  cluster-name: "{{ .Values.clusterName }}"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cluster-name-patcher
  namespace: open-cluster-management
spec:
  template:
    spec:
      containers:
      - name: patcher
        image: busybox
        command:
        - /bin/sh
        - -c
        - |
          # Patch cluster name
          oc patch cluster local-cluster --type merge -p '{"metadata":{"name":"'$CLUSTER_NAME'"}}'
        env:
        - name: CLUSTER_NAME
          valueFrom:
            configMapKeyRef:
              name: cluster-name-patch
              key: cluster-name
```

### Kustomization

```yaml
# kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- cluster-name-patch.yaml

patchesStrategicMerge:
- cluster-name-patch.yaml

labels:
- includeSelectors: false
  pairs:
    app.kubernetes.io/part-of: platform-management
    component: custom-cluster-name
```

## ⚙️ Configuration

### Cluster Name Values

```yaml
# values.yaml
clusterName: "labhub"
environment: "lab"
clusterType: "hub"
```

### Environment-Specific Configuration

**Development:**
```yaml
clusterName: "dev-hub"
environment: "development"
clusterType: "hub"
```

**Production:**
```yaml
clusterName: "prod-hub"
environment: "production"
clusterType: "hub"
```

## 🚀 Usage Examples

### 1. Deploy Custom Cluster Name

```bash
# Deploy cluster name patch
kustomize build clusters/labhub/capabilities/custom-cluster-name/ | oc apply -f -

# Verify deployment
oc get configmap cluster-name-patch -n open-cluster-management
oc get deployment cluster-name-patcher -n open-cluster-management
```

### 2. Verify Cluster Name

```bash
# Check cluster name
oc get cluster local-cluster -o jsonpath='{.metadata.name}'

# Check cluster labels
oc get cluster local-cluster -o yaml | grep -A 5 -B 5 "name"

# Check cluster status
oc describe cluster local-cluster
```

### 3. Update Cluster Name

```bash
# Update cluster name
oc patch configmap cluster-name-patch -n open-cluster-management --type merge -p '{"data":{"cluster-name":"new-cluster-name"}}'

# Restart patcher
oc rollout restart deployment/cluster-name-patcher -n open-cluster-management
```

### 4. Remove Custom Cluster Name

```bash
# Remove cluster name patch
oc delete -f clusters/labhub/capabilities/custom-cluster-name/

# Verify removal
oc get configmap cluster-name-patch -n open-cluster-management
```

## 🚨 Troubleshooting

### Common Issues

1. **Cluster Name Not Updated**
   ```bash
   # Check patcher deployment
   oc get deployment cluster-name-patcher -n open-cluster-management
   
   # Check patcher logs
   oc logs -n open-cluster-management deployment/cluster-name-patcher
   
   # Check cluster name
   oc get cluster local-cluster -o jsonpath='{.metadata.name}'
   ```

2. **Patcher Deployment Failed**
   ```bash
   # Check deployment status
   oc describe deployment cluster-name-patcher -n open-cluster-management
   
   # Check pod status
   oc get pods -n open-cluster-management -l app=cluster-name-patcher
   
   # Check pod logs
   oc logs -n open-cluster-management pod/cluster-name-patcher-xxx
   ```

3. **ConfigMap Issues**
   ```bash
   # Check configmap
   oc get configmap cluster-name-patch -n open-cluster-management
   
   # Check configmap data
   oc get configmap cluster-name-patch -n open-cluster-management -o yaml
   
   # Check configmap usage
   oc get deployment cluster-name-patcher -n open-cluster-management -o yaml | grep -A 5 -B 5 configMapKeyRef
   ```

4. **RBAC Issues**
   ```bash
   # Check RBAC permissions
   oc auth can-i patch cluster --as=system:serviceaccount:open-cluster-management:cluster-name-patcher
   
   # Check service account
   oc get serviceaccount cluster-name-patcher -n open-cluster-management
   
   # Check role binding
   oc get rolebinding cluster-name-patcher -n open-cluster-management
   ```

### Debug Mode

Enable debug mode for detailed troubleshooting:

```bash
# Kustomize debug
kustomize build clusters/labhub/capabilities/custom-cluster-name/ --enable-helm --enable-alpha-plugins

# Patcher debug
oc patch deployment cluster-name-patcher -n open-cluster-management --type merge -p '{"spec":{"template":{"spec":{"containers":[{"name":"patcher","command":["/bin/sh","-c","set -x; oc patch cluster local-cluster --type merge -p '\''{\"metadata\":{\"name\":\"'$CLUSTER_NAME'\"}}'\''"]}]}}}}'

# Cluster debug
oc get cluster local-cluster -o yaml | grep -A 10 -B 10 "metadata"
```

### Log Analysis

```bash
# Check patcher logs
oc logs -n open-cluster-management deployment/cluster-name-patcher

# Check cluster logs
oc logs -n open-cluster-management deployment/multicluster-observability-operator

# Check ACM logs
oc logs -n open-cluster-management deployment/governance-policy-framework
```

## ⚠️ Deprecation Notice

### ACM-1290 Resolution

This capability is a temporary workaround and will be **deprecated** once ACM-1290 is resolved.

**Timeline**: This capability should be removed when:
- ACM-1290 is fixed in a future ACM release
- Cluster names are properly managed by ACM
- Multiple ACM instances can be distinguished

**Migration Path**:
1. Monitor ACM-1290 status
2. Test ACM release with fix
3. Remove custom cluster name capability
4. Update cluster management procedures

**Reference**: [ACM-1290 Issue](https://issues.redhat.com/browse/ACM-1290)

## 🤝 Contributing

### Development Workflow

1. **Create Feature Branch**:
   ```bash
   git checkout -b feature/custom-cluster-name-update
   ```

2. **Make Changes**:
   - Update cluster name patch
   - Modify patcher deployment
   - Update documentation

3. **Test Changes**:
   ```bash
   # Test cluster name patch
   kustomize build clusters/labhub/capabilities/custom-cluster-name/
   
   # Test with deployment
   oc apply -f clusters/labhub/capabilities/custom-cluster-name/
   ```

4. **Create Pull Request**:
   - Include description of changes
   - Reference ACM-1290 issue
   - Ensure all tests pass

### Code Standards

- **Consistent Structure**: Follow established directory structure
- **Documentation**: Include README.md for new components
- **Testing**: Add tests for new functionality
- **Naming**: Use descriptive, consistent naming conventions

## 📄 License

This project is part of the ODFL OpenShift vSphere IPI Installation automation framework.

---

**Note**: This is a temporary workaround for ACM-1290. Monitor the issue status and plan for deprecation once the fix is available.
