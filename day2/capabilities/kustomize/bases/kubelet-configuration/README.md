# Kubelet Configuration

This directory contains Kustomize base configurations for OpenShift kubelet tuning and performance optimization.

## 📋 Table of Contents

- [Overview](#-overview)
- [Directory Structure](#-directory-structure)
- [Configuration Components](#-configuration-components)
- [Node Sizing](#-node-sizing)
- [Usage Examples](#-usage-examples)
- [Troubleshooting](#-troubleshooting)
- [References](#-references)
- [Contributing](#-contributing)
- [License](#-license)

## 🎯 Overview

The kubelet configuration capability provides:

- **Node Sizing**: Optimized resource allocation for different node types
- **Pod Limits**: Configurable maximum pods per node
- **Resource Tuning**: CPU and memory optimization
- **Performance Settings**: Kubelet performance parameters

## 📁 Directory Structure

```
kubelet-configuration/
├── README.md                           # This file
├── kustomization.yaml                  # Main kustomization
├── kubelet-config.yaml                 # Kubelet configuration
├── node-sizing.yaml                    # Node sizing configuration
└── pod-limits.yaml                     # Pod limits configuration
```

## 🔧 Configuration Components

### 1. Kubelet Configuration

**Purpose**: Core kubelet performance and resource settings

**Key Settings:**
- CPU and memory limits
- Pod eviction thresholds
- Resource reservation
- Performance tuning

**Configuration:**
```yaml
# kubelet-config.yaml
apiVersion: machineconfiguration.openshift.io/v1
kind: KubeletConfig
metadata:
  name: kubelet-config
spec:
  machineConfigPoolSelector:
    matchLabels:
      pools.operator.machineconfiguration.openshift.io/worker: ""
  kubeletConfig:
    maxPods: 250
    podsPerCore: 10
    systemReserved:
      cpu: "100m"
      memory: "1Gi"
    kubeReserved:
      cpu: "100m"
      memory: "1Gi"
```

### 2. Node Sizing

**Purpose**: Node-specific resource allocation and sizing

**Configuration:**
```yaml
# node-sizing.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: node-sizing-config
  namespace: openshift-config
data:
  node-sizing.env: |
    # Node sizing configuration
    NODE_CPU_LIMIT=4
    NODE_MEMORY_LIMIT=8Gi
    POD_CPU_LIMIT=500m
    POD_MEMORY_LIMIT=1Gi
```

### 3. Pod Limits

**Purpose**: Maximum pods per node configuration

**Configuration:**
```yaml
# pod-limits.yaml
apiVersion: machineconfiguration.openshift.io/v1
kind: KubeletConfig
metadata:
  name: pod-limits-config
spec:
  machineConfigPoolSelector:
    matchLabels:
      pools.operator.machineconfiguration.openshift.io/worker: ""
  kubeletConfig:
    maxPods: 250
    podsPerCore: 10
```

## 📊 Node Sizing

### Node Verification

Node sizing configuration is stored on each node at `/etc/node-sizing.env`:

```bash
# Check node sizing on a node
oc debug node/node-name -- chroot /host cat /etc/node-sizing.env

# Verify node resources
oc describe node node-name | grep -A 10 "Allocated resources"
```

### Sizing Guidelines

**Small Nodes (2-4 CPU, 4-8GB RAM):**
- maxPods: 110
- podsPerCore: 10
- systemReserved: cpu=100m, memory=1Gi

**Medium Nodes (4-8 CPU, 8-16GB RAM):**
- maxPods: 250
- podsPerCore: 10
- systemReserved: cpu=200m, memory=2Gi

**Large Nodes (8+ CPU, 16+GB RAM):**
- maxPods: 500
- podsPerCore: 10
- systemReserved: cpu=500m, memory=4Gi

## 🚀 Usage Examples

### 1. Deploy Kubelet Configuration

```bash
# Deploy kubelet configuration
kustomize build capabilities/kustomize/bases/kubelet-configuration/ | oc apply -f -

# Verify deployment
oc get kubeletconfig
oc get machineconfigpool
```

### 2. Customize Node Sizing

```bash
# Create custom node sizing
cat > custom-node-sizing.yaml << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: custom-node-sizing
  namespace: openshift-config
data:
  node-sizing.env: |
    NODE_CPU_LIMIT=8
    NODE_MEMORY_LIMIT=16Gi
    POD_CPU_LIMIT=1000m
    POD_MEMORY_LIMIT=2Gi
EOF

# Apply custom sizing
oc apply -f custom-node-sizing.yaml
```

### 3. Update Pod Limits

```bash
# Update pod limits for specific node pool
oc patch kubeletconfig kubelet-config --type merge -p '{"spec":{"kubeletConfig":{"maxPods":500}}}'

# Verify changes
oc get kubeletconfig kubelet-config -o yaml
```

### 4. Apply to Specific Node Pools

```bash
# Apply to worker nodes only
kustomize build capabilities/kustomize/bases/kubelet-configuration/ | oc apply -f -

# Apply to specific node pool
oc label machineconfigpool worker custom-sizing=enabled
```

## 🚨 Troubleshooting

### Common Issues

1. **Kubelet Configuration Not Applied**
   ```bash
   # Check kubelet config status
   oc get kubeletconfig
   
   # Check machine config pool status
   oc get machineconfigpool
   
   # Check node status
   oc get nodes
   ```

2. **Node Sizing Issues**
   ```bash
   # Check node sizing file
   oc debug node/node-name -- chroot /host cat /etc/node-sizing.env
   
   # Check node resources
   oc describe node node-name
   
   # Check node capacity
   oc get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.capacity.cpu}{"\t"}{.status.capacity.memory}{"\n"}{end}'
   ```

3. **Pod Limits Not Working**
   ```bash
   # Check pod limits
   oc get kubeletconfig -o yaml | grep -A 5 -B 5 maxPods
   
   # Check node pod count
   oc get pods --all-namespaces --field-selector spec.nodeName=node-name | wc -l
   
   # Check kubelet logs
   oc logs -n openshift-machine-config-operator deployment/machine-config-operator
   ```

4. **Resource Reservation Issues**
   ```bash
   # Check resource reservations
   oc get kubeletconfig -o yaml | grep -A 10 -B 5 systemReserved
   
   # Check node allocatable resources
   oc get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.allocatable.cpu}{"\t"}{.status.allocatable.memory}{"\n"}{end}'
   ```

### Debug Mode

Enable debug mode for detailed troubleshooting:

```bash
# Kustomize debug
kustomize build capabilities/kustomize/bases/kubelet-configuration/ --enable-helm --enable-alpha-plugins

# Machine config debug
oc get machineconfig -o yaml | grep -A 10 -B 10 kubelet

# Node debug
oc debug node/node-name -- chroot /host journalctl -u kubelet
```

### Log Analysis

```bash
# Check machine config operator logs
oc logs -n openshift-machine-config-operator deployment/machine-config-operator

# Check kubelet logs
oc debug node/node-name -- chroot /host journalctl -u kubelet

# Check node status
oc describe node node-name
```

## 📚 References

### OpenShift Documentation

- [Sizing guidance for hosted control planes](https://docs.openshift.com/container-platform/4.17/hosted_control_planes/hcp-prepare/hcp-sizing-guidance.html#hcp-pod-limits_hcp-sizing-guidance)
- [Allocating resources for nodes in an OpenShift Container Platform cluster](https://docs.openshift.com/container-platform/4.16/nodes/nodes/nodes-nodes-resources-configuring.html#nodes-nodes-resources-configuring-auto_nodes-nodes-resources-configuring)
- [Configuring the maximum number of pods per node](https://docs.openshift.com/container-platform/4.17/nodes/nodes/nodes-nodes-managing-max-pods.html#nodes-nodes-managing-max-pods-proc_nodes-nodes-managing-max-pods)

### Additional Resources

- [Kubernetes Node Sizing Best Practices](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)
- [OpenShift Performance Tuning](https://docs.openshift.com/container-platform/4.17/scalability_and_performance/performance-tuning.html)
- [Machine Config Operator](https://docs.openshift.com/container-platform/4.17/post_installation_configuration/machine-configuration-tasks.html)

## 🤝 Contributing

### Development Workflow

1. **Create Feature Branch**:
   ```bash
   git checkout -b feature/kubelet-config-update
   ```

2. **Make Changes**:
   - Update kubelet configuration
   - Modify node sizing settings
   - Update documentation

3. **Test Changes**:
   ```bash
   # Test configuration build
   kustomize build capabilities/kustomize/bases/kubelet-configuration/
   
   # Test with validation
   kustomize build capabilities/kustomize/bases/kubelet-configuration/ | oc apply --dry-run=client -f -
   ```

4. **Create Pull Request**:
   - Include description of changes
   - Reference any related issues
   - Ensure all tests pass

### Code Standards

- **Consistent Structure**: Follow established directory structure
- **Documentation**: Include README.md for new configurations
- **Testing**: Add tests for new functionality
- **Naming**: Use descriptive, consistent naming conventions

## 📄 License

This project is part of the ODFL OpenShift vSphere IPI Installation automation framework.

---

**Note**: Always test kubelet configuration changes in a development environment before deploying to production. Consider the impact of changes on node performance and pod scheduling.

