# OpenShift vSphere IPI Installation - User Guide Summary

## 🎯 **Quick Start Guide**

### **Prerequisites Checklist**
- [ ] VMware vSphere 7.0+ with appropriate permissions
- [ ] Red Hat OpenShift pull secret
- [ ] SSH key pair for cluster access
- [ ] Custom certificates (if required)
- [ ] Podman/Docker installed
- [ ] Network configuration (DNS, load balancer)
- [ ] 8GB+ RAM and 20GB+ storage
- [ ] Internet access for image pulls

### **5-Minute Installation**
```bash
# 1. Clone repository
git clone <repository-url>
cd openshift-vsphere-ipi-install

# 2. Generate SSH keys
./ssh-keygen.sh

# 3. Install prerequisites
cd automation-ee/prep
./install-ansible-tools.sh

# 4. Build execution environment
cd ../ocp-provision-ee
./builder.sh

# 5. Deploy cluster
cd ../../
./010-run-prep-cluster-install.sh lab lab
./030-run-install-and-monitor.sh lab lab
```

## 🏗️ **Architecture Overview**

### **System Components**

```
┌─────────────────────────────────────────────────────────────┐
│                    Execution Environment                     │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────┐ │
│  │   Ansible Core  │  │ OpenShift CLI   │  │    Helm     │ │
│  │   Collections   │  │   kubectl       │  │   Charts    │ │
│  └─────────────────┘  └─────────────────┘  └─────────────┘ │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Ansible Playbooks                        │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────┐ │
│  │   Prep Cluster  │  │ Install &       │  │   GitOps    │ │
│  │   Secrets       │  │ Monitor         │  │   Operator  │ │
│  └─────────────────┘  └─────────────────┘  └─────────────┘ │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    VMware vSphere                           │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────┐ │
│  │   vCenter       │  │   ESXi Hosts    │  │  Storage    │ │
│  │   Management    │  │   Compute       │  │  Datastores │ │
│  └─────────────────┘  └─────────────────┘  └─────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## 📋 **Step-by-Step Installation**

### **Phase 1: Environment Preparation**

#### **1.1 System Setup**
```bash
# Install required packages
sudo dnf install -y podman git ansible-core

# Start Podman service
sudo systemctl enable --now podman

# Verify installation
podman --version
ansible --version
```

#### **1.2 Repository Setup**
```bash
# Clone repository
git clone <repository-url>
cd openshift-vsphere-ipi-install

# Set permissions
chmod +x *.sh
chmod +x automation-ee/*/*.sh
```

#### **1.3 SSH Key Generation**
```bash
# Generate SSH key pair
./ssh-keygen.sh

# Verify keys
ls -la ~/.ssh/
```

### **Phase 2: Execution Environment**

#### **2.1 Prerequisites Installation**
```bash
# Install Ansible tools
cd automation-ee/prep
./install-ansible-tools.sh

# Verify installation
ansible-galaxy collection list
```

#### **2.2 Build Execution Environment**
```bash
# Build execution environment
cd ../ocp-provision-ee
./builder.sh

# Verify build
podman images | grep ocp-provision-ee
```

#### **2.3 Test Execution Environment**
```bash
# Test container functionality
podman run --rm ocp-provision-ee:latest ansible --version
podman run --rm ocp-provision-ee:latest oc version
```

### **Phase 3: Cluster Deployment**

#### **3.1 Prepare Cluster Environment**
```bash
# Run preparation playbook
./010-run-prep-cluster-install.sh lab lab

# Verify preparation
ls -la ansible/install-dir/
```

#### **3.2 Install and Monitor Cluster**
```bash
# Deploy OpenShift cluster
./030-run-install-and-monitor.sh lab lab

# Monitor installation progress
tail -f 030-install-output.out
```

#### **3.3 Install GitOps Operator**
```bash
# Install GitOps capabilities
./040-run-install-gitops.sh lab lab

# Verify GitOps installation
oc get pods -n openshift-gitops
```

## ⚙️ **Configuration Management**

### **Environment-Specific Configuration**

#### **Development Environment**
```bash
# Use development configuration
export ENVIRONMENT=dev
./010-run-prep-cluster-install.sh dev dev
```

#### **Production Environment**
```bash
# Use production configuration
export ENVIRONMENT=prod
./010-run-prep-cluster-install.sh prod prod
```

### **Custom Configuration**

#### **Custom Cluster Name**
```bash
# Set custom cluster name
export CLUSTER_NAME=my-custom-cluster
./010-run-prep-cluster-install.sh my-custom-cluster lab
```

#### **Custom vSphere Settings**
```bash
# Edit vSphere configuration
vim ansible/group_vars/cluster/lab/all.yaml

# Update vCenter settings
vcenter_server: "vcenter.example.com"
vcenter_username: "admin@vsphere.local"
vcenter_password: "{{ vault_vcenter_password }}"
```

## 🔐 **Secret Management**

### **Ansible Vault Setup**

#### **Create Vault Password**
```bash
# Generate vault password
openssl rand -base64 32 > vault-password.txt

# Set permissions
chmod 600 vault-password.txt
```

#### **Encrypt Secrets**
```bash
# Encrypt sensitive files
ansible-vault encrypt ansible/secrets/lab/secrets.yaml

# Edit encrypted file
ansible-vault edit ansible/secrets/lab/secrets.yaml
```

#### **Common Secrets**
```yaml
# secrets.yaml content
vault_vcenter_password: "your-vcenter-password"
vault_pull_secret: |
  {
    "auths": {
      "registry.redhat.io": {
        "auth": "your-pull-secret"
      }
    }
  }
vault_ssh_private_key: |
  -----BEGIN OPENSSH PRIVATE KEY-----
  your-ssh-private-key
  -----END OPENSSH PRIVATE KEY-----
```

## 🚀 **Usage Examples**

### **Basic Cluster Operations**

#### **Deploy Complete Cluster**
```bash
# Full cluster deployment
./010-run-prep-cluster-install.sh lab lab
./030-run-install-and-monitor.sh lab lab
./040-run-install-gitops.sh lab lab
```

#### **Deploy Specific Components**
```bash
# Deploy only preparation
./010-run-prep-cluster-install.sh lab lab

# Deploy only cluster installation
./030-run-install-and-monitor.sh lab lab

# Deploy only GitOps
./040-run-install-gitops.sh lab lab
```

### **Advanced Operations**

#### **Using Execution Environment Directly**
```bash
# Run Ansible playbook
podman run --rm -it \
  -v $(pwd)/ansible:/runner/project/ansible:Z \
  -e KUBECONFIG=/runner/project/ansible/install-dir/auth/kubeconfig \
  ocp-provision-ee:latest \
  ansible-playbook /runner/project/ansible/install_and_monitor_cluster.yaml

# Run OpenShift CLI commands
podman run --rm -it \
  -v $(pwd)/ansible:/runner/project/ansible:Z \
  -e KUBECONFIG=/runner/project/ansible/install-dir/auth/kubeconfig \
  ocp-provision-ee:latest \
  oc get nodes
```

#### **Helm Operations**
```bash
# Install Helm chart
podman run --rm -it \
  -v $(pwd)/charts:/runner/project/charts:Z \
  -e KUBECONFIG=/runner/project/ansible/install-dir/auth/kubeconfig \
  ocp-provision-ee:latest \
  helm install my-app ./charts/my-app

# List Helm releases
podman run --rm -it \
  -e KUBECONFIG=/runner/project/ansible/install-dir/auth/kubeconfig \
  ocp-provision-ee:latest \
  helm list
```

## 🔍 **Monitoring and Validation**

### **Cluster Health Checks**

#### **Check Cluster Status**
```bash
# Check cluster operators
oc get clusteroperators

# Check node status
oc get nodes

# Check pod status
oc get pods -A
```

#### **Validate Installation**
```bash
# Run validation playbook
ansible-playbook ansible/validate_cluster_and_kubeconfig.yaml

# Check cluster health
oc get clusterversion
```

### **Monitoring Commands**

#### **Resource Usage**
```bash
# Check resource usage
oc top nodes
oc top pods -A

# Check storage usage
oc get pv
oc get pvc -A
```

#### **Log Analysis**
```bash
# Check cluster logs
oc logs -n openshift-cluster-version deployment/cluster-version-operator

# Check node logs
oc logs -n openshift-machine-config-operator deployment/machine-config-operator
```

## 🚨 **Troubleshooting**

### **Common Issues**

#### **Build Failures**
```bash
# Check build logs
cat automation-ee/ocp-provision-ee/builder.out

# Clean and rebuild
cd automation-ee/ocp-provision-ee
./clean-build-env.sh
./builder.sh --clean
```

#### **Container Issues**
```bash
# Check container logs
podman logs <container-id>

# Verify image exists
podman images | grep ocp-provision-ee

# Test container execution
podman run --rm ocp-provision-ee:latest ansible --version
```

#### **Permission Issues**
```bash
# Fix SELinux contexts
sudo setsebool -P container_manage_cgroup on

# Fix file permissions
chmod +x *.sh
chmod +x automation-ee/*/*.sh
```

### **Debug Mode**

#### **Enable Verbose Output**
```bash
# Run with verbose output
export ANSIBLE_VERBOSITY=4
./030-run-install-and-monitor.sh lab lab
```

#### **Debug Container Execution**
```bash
# Run container with debug
podman run --rm -it \
  -e ANSIBLE_VERBOSITY=4 \
  ocp-provision-ee:latest \
  ansible-playbook playbook.yml
```

## 📚 **Documentation Reference**

### **Main Documentation**

- **`README.md`**: Main project documentation
- **`automation-ee/README.md`**: Execution environment guide
- **`ansible/README.md`**: Ansible automation guide
- **`day2/README.md`**: Day-2 operations guide

### **Quick Reference**

| Command | Purpose |
|---------|---------|
| `./ssh-keygen.sh` | Generate SSH keys |
| `./010-run-prep-cluster-install.sh` | Prepare cluster environment |
| `./030-run-install-and-monitor.sh` | Install and monitor cluster |
| `./040-run-install-gitops.sh` | Install GitOps operator |
| `./099-destroy-cluster.sh` | Destroy cluster |
| `oc get nodes` | Check cluster nodes |
| `oc get pods -A` | Check all pods |
| `helm list` | List Helm releases |

### **Useful Files**

- **`ansible/install-dir/auth/kubeconfig`**: Cluster kubeconfig
- **`ansible/install-dir/auth/kubeadmin-password`**: Admin password
- **`ansible/install-dir/metadata.json`**: Cluster metadata
- **`vault-password.txt`**: Ansible Vault password

## 🎯 **Best Practices**

### **Security**

- Always use Ansible Vault for sensitive data
- Regularly rotate passwords and keys
- Use least privilege access principles
- Monitor and audit all activities

### **Operations**

- Test changes in development first
- Use version control for all configurations
- Document all customizations
- Maintain regular backups

### **Performance**

- Monitor resource usage regularly
- Use appropriate cluster sizing
- Optimize container resource limits
- Implement proper monitoring and alerting

---

**User Guide Summary**: This guide provides everything needed to successfully deploy and manage OpenShift clusters on VMware vSphere using the automated installation framework. Follow the step-by-step instructions for a successful deployment.