# OpenShift Container Platform Test Environment

This directory contains a comprehensive test environment for OpenShift Container Platform (OCP) manifest generation and validation. It provides a safe, isolated environment for testing OpenShift cluster configurations before actual deployment.

## 📋 Table of Contents

- [Overview](#-overview)
- [Directory Structure](#-directory-structure)
- [Test Script](#-test-script)
- [Install Directory](#-install-directory)
- [Prerequisites](#-prerequisites)
- [Usage Examples](#-usage-examples)
- [Configuration Files](#️-configuration-files)
- [Troubleshooting](#-troubleshooting)
- [Output and Logging](#-output-and-logging)
- [Security Considerations](#-security-considerations)
- [Best Practices](#-best-practices)
- [Related Scripts](#-related-scripts)
- [References](#-references)

## 🎯 Overview

The `00-ocp-test` directory serves as a comprehensive testing framework for OpenShift cluster configurations. It provides:

- **Safe Testing Environment**: Isolated testing without affecting production configurations
- **Manifest Generation**: Automated OpenShift manifest creation and validation
- **Container Integration**: Uses execution environment for consistent tooling
- **Comprehensive Validation**: Tests all aspects of OpenShift cluster configuration
- **Debugging Support**: Detailed logging and error reporting

## 📁 Directory Structure

```
00-ocp-test/
├── README.md                           # This file - Main documentation
├── 00-test-manifest.sh                 # Main test script for manifest generation
├── 00-test-manifest.out                # Test execution output log
└── install-dir/                        # OpenShift installation directory
    ├── README.md                       # Install directory documentation
    ├── install-config.yaml             # Active cluster configuration
    ├── cluster-api/                    # Cluster API manifests
    │   ├── 000_capi-namespace.yaml
    │   ├── 01_capi-cluster-0.yaml
    │   ├── 01_vsphere-cluster-0.yaml
    │   └── 01_vsphere-creds-0.yaml
    ├── manifests/                      # OpenShift cluster manifests
    │   ├── cloud-provider-config.yaml
    │   ├── cluster-config.yaml
    │   ├── cluster-dns-02-config.yml
    │   ├── cluster-infrastructure-02-config.yml
    │   ├── cluster-ingress-02-config.yml
    │   ├── cluster-network-02-config.yml
    │   ├── cluster-proxy-01-config.yaml
    │   ├── cluster-scheduler-02-config.yml
    │   ├── cvo-overrides.yaml
    │   ├── kube-cloud-config.yaml
    │   ├── kube-system-configmap-root-ca.yaml
    │   ├── machine-config-server-tls-secret.yaml
    │   ├── openshift-config-secret-pull-secret.yaml
    │   └── user-ca-bundle-config.yaml
    └── openshift/                      # OpenShift-specific configurations
        ├── 99_cloud-creds-secret.yaml
        ├── 99_feature-gate.yaml
        ├── 99_kubeadmin-password-secret.yaml
        ├── 99_openshift-cluster-api_master-machines-0.yaml
        ├── 99_openshift-cluster-api_master-machines-1.yaml
        ├── 99_openshift-cluster-api_master-machines-2.yaml
        ├── 99_openshift-cluster-api_master-user-data-secret.yaml
        ├── 99_openshift-cluster-api_worker-machineset-0.yaml
        ├── 99_openshift-cluster-api_worker-user-data-secret.yaml
        ├── 99_openshift-machine-api_master-control-plane-machine-set.yaml
        ├── 99_openshift-machineconfig_99-master-ssh.yaml
        ├── 99_openshift-machineconfig_99-worker-ssh.yaml
        ├── 99_role-cloud-creds-secret-reader.yaml
        └── openshift-install-manifests.yaml
```

## 🧪 Test Script

### `00-test-manifest.sh`

The main test script provides comprehensive OpenShift manifest generation and validation.

#### **Key Features**

- **Clean Test Environment**: Creates isolated test directories for manifest generation
- **Prerequisites Validation**: Checks for required files and execution environment
- **Multiple Execution Modes**: Normal, verbose, and dry-run modes
- **Container Integration**: Uses execution environment for consistent tooling
- **Comprehensive Logging**: Timestamped, color-coded output with verbose options
- **Error Handling**: Robust error checking with helpful error messages

#### **Command-Line Options**

| Option | Description |
|--------|-------------|
| `-h, --help` | Show comprehensive help information |
| `-v, --verbose` | Enable detailed logging output |
| `-d, --dry-run` | Show what would be done without executing |

#### **Usage Examples**

```bash
# Show help
./00-test-manifest.sh -h

# Normal execution
./00-test-manifest.sh

# Verbose output
./00-test-manifest.sh --verbose

# Dry run (preview mode)
./00-test-manifest.sh --dry-run

# Combined options
./00-test-manifest.sh --verbose --dry-run
```

#### **Script Workflow**

1. **Prerequisites Validation**
   - Checks for source `install-config.yaml.orig` file
   - Verifies execution environment image exists
   - Creates required test directories

2. **Environment Setup**
   - Displays configuration information
   - Lists source directory contents
   - Creates/verifies test directory structure

3. **Cleanup Phase**
   - Removes old manifest files from test directories
   - Ensures clean starting state

4. **Configuration Copy**
   - Copies `install-config.yaml.orig` to test directory
   - Preserves original configuration for testing

5. **Manifest Generation**
   - Runs `openshift-install create manifests` in execution environment container
   - Generates all required OpenShift manifests
   - Uses proper volume mounting and permissions

6. **Results Display**
   - Shows final manifest directory contents
   - Confirms successful completion
   - Provides summary of generated files

## 📂 Install Directory

The `install-dir/` directory serves as the working directory for OpenShift installer operations.

### **Purpose**

- **Target Working Directory**: Used by OpenShift installer (`openshift-install --dir=<install-dir> ...`)
- **Configuration Storage**: Holds cluster's `install-config.yaml` and generated artifacts
- **Manifest Repository**: Contains all generated Kubernetes/OpenShift manifests
- **Authentication Artifacts**: Stores credentials and bootstrap auth artifacts

### **Typical Contents**

- **`install-config.yaml`**: Cluster configuration used by the installer
- **`manifests/`**: Generated Kubernetes/OpenShift manifests and user-managed overrides
- **`auth/`**: Credentials and bootstrap auth artifacts created during install
- **`kubeconfig`**: Created post-install (on success)
- **`kubeadmin-password`**: Admin password created post-install
- **`metadata.json`**: Installer metadata for the cluster
- **`*.ign`**: Ignition and other generated assets
- **`openshift/`**: OpenShift-specific configurations

### **Basic Workflow**

1. **Prepare Configuration**:
   ```bash
   cp ../templates/install-config.yaml.j2 ./install-config.yaml
   ```

2. **Generate Manifests**:
   ```bash
   openshift-install create manifests --dir=/path/to/install-dir
   ```

3. **Generate Ignition Configs** (Optional):
   ```bash
   openshift-install create ignition-configs --dir=/path/to/install-dir
   ```

4. **Create Cluster** (for assisted/IPI flows):
   ```bash
   openshift-install create cluster --dir=/path/to/install-dir
   ```

5. **Inspect Results**:
   ```bash
   ls -la auth/ kubeconfig metadata.json
   ```

## 🔧 Prerequisites

### **Required Software**

- **Podman**: Container runtime for execution environment
- **Execution Environment**: `ocp-provision-ee:latest` image must be built
- **Source Configuration**: `../ansible/install-dir/install-config.yaml.orig` must exist

### **Build Execution Environment**

Before using this script, build the execution environment:

```bash
cd automation-ee/ocp-provision-ee/
./builder.sh
```

### **Execution Environment Features**

- **Base Image**: `registry.redhat.io/ansible-automation-platform-25/ee-supported-rhel9:latest`
- **Custom Image**: `ocp-provision-ee:latest`
- **Tools Included**:
  - OpenShift installer tools (openshift-install, oc, kubectl)
  - Helm v3.16.3
  - Kustomize v5.5.0
  - Policy Generator v1.15.0
  - Corporate certificates and configurations

## 🚀 Usage Examples

### **1. Basic Manifest Generation**

```bash
# Run the test script
./00-test-manifest.sh

# Check generated manifests
ls -la install-dir/manifests/
ls -la install-dir/openshift/
ls -la install-dir/cluster-api/
```

### **2. Verbose Testing**

```bash
# Run with detailed output
./00-test-manifest.sh --verbose

# Check the output log
cat 00-test-manifest.out
```

### **3. Dry Run Testing**

```bash
# Preview operations without executing
./00-test-manifest.sh --dry-run

# Verify what would be done
```

### **4. Manual Manifest Generation**

```bash
# Generate manifests manually
podman run --rm \
  --ipc=host \
  --user=root \
  --group-add=root \
  -v ./install-dir:/runner/project:Z \
  ocp-provision-ee:latest \
  openshift-install create manifests --dir=/runner/project
```

## ⚙️ Configuration Files

### **Install Configuration**

The `install-config.yaml` file contains the cluster configuration:

```yaml
apiVersion: v1
baseDomain: example.com
metadata:
  name: test-cluster
platform:
  vsphere:
    vcenter: vcenter.example.com
    username: admin@vsphere.local
    password: password
    datacenter: datacenter
    defaultDatastore: datastore
    cluster: cluster
    network: network
    diskType: thin
pullSecret: '{"auths":{...}}'
sshKey: ssh-rsa AAAAB3NzaC1yc2E...
```

### **Generated Manifests**

The script generates several types of manifests:

#### **Cluster API Manifests** (`cluster-api/`)
- Cluster API namespace and resources
- vSphere cluster configuration
- vSphere credentials

#### **OpenShift Manifests** (`manifests/`)
- Cloud provider configuration
- Cluster configuration (DNS, networking, ingress)
- Proxy configuration
- Scheduler configuration
- CVO overrides
- Root CA configuration
- Machine config server TLS secrets
- Pull secret configuration
- User CA bundle

#### **OpenShift-Specific Configs** (`openshift/`)
- Cloud credentials secrets
- Feature gate configuration
- kubeadmin password secret
- Master machine configurations
- Worker machine set
- User data secrets
- Machine API control plane machine set
- SSH machine configs
- Cloud credentials secret reader role

## 🚨 Troubleshooting

### **Common Issues**

#### **Missing Source Configuration**
```
ERROR: Source install config not found: ../ansible/install-dir/install-config.yaml.orig
```
**Solution**: Ensure the cluster initialization process has created the original install config.

#### **Missing Execution Environment**
```
ERROR: Execution environment image 'ocp-provision-ee:latest' not found
```
**Solution**: Build the execution environment:
```bash
cd automation-ee/ocp-provision-ee/
./builder.sh
```

#### **Permission Issues**
**Solution**: Ensure Podman is running and has proper permissions for volume mounting.

### **Debugging Tips**

- Use `--verbose` option for detailed logging
- Use `--dry-run` to preview operations without executing
- Check Podman image list: `podman images | grep ocp-provision-ee`
- Verify source file exists: `ls -la ../ansible/install-dir/install-config.yaml.orig`

### **Validation Commands**

```bash
# Validate YAML syntax
yamllint install-dir/manifests/

# Validate Kubernetes resources
kubeval --exit-status install-dir/manifests/*.yaml

# Check specific manifests
oc apply --dry-run=client -f install-dir/manifests/
```

## 📊 Output and Logging

### **Color-Coded Output**

- **Yellow**: Actions in progress and informational messages
- **Green**: Successful operations and completion messages
- **Red**: Errors and failure conditions

### **Logging Levels**

- **Normal**: Standard progress messages with timestamps
- **Verbose**: Additional details about operations and file paths
- **Dry Run**: Preview of what would be executed

### **Example Output**

```
2024-10-01 18:30:15 Listing cluster provision install directory contents: [../ansible/install-dir]
2024-10-01 18:30:15 Cleaning up old manifests...
2024-10-01 18:30:15 Copying install-config.yaml.orig to install-dir...
2024-10-01 18:30:15 Creating OpenShift manifests...
2024-10-01 18:30:20 Manifests created successfully
2024-10-01 18:30:20 All steps completed successfully! 🎉
```

## 🔒 Security Considerations

- **Container Isolation**: Runs in isolated container environment
- **Volume Mounting**: Uses SELinux context (`:Z`) for proper file access
- **Root Access**: Container runs as root for system-level operations
- **Network Access**: Container has full network access for API calls
- **Sensitive Data**: Do not commit pull secrets, passwords, or private keys to public repositories

## 💡 Best Practices

1. **Always validate prerequisites** before running the script
2. **Use dry-run mode** to preview operations before execution
3. **Check verbose output** for detailed operation information
4. **Review generated manifests** to ensure proper configuration
5. **Clean up test directories** after testing if needed
6. **Keep original configurations** in source control (with sensitive data redacted)
7. **Document manifest overrides** and explain why they are required
8. **Use vaults or CI secrets** for sensitive values

## 🔗 Related Scripts

- `../ee-bash.sh`: Interactive execution environment launcher
- `../030-run-install-and-monitor.sh`: Full cluster installation
- `../040-run-install-gitops.sh`: GitOps operator installation
- `../automation-ee/ocp-provision-ee/builder.sh`: Build execution environment

## 📚 References

- [OpenShift Documentation: Installing Clusters](https://docs.openshift.com/container-platform/latest/installing/index.html)
- [OpenShift Installer GitHub Repository](https://github.com/openshift/installer)
- [Ansible Execution Environments Documentation](https://docs.ansible.com/automation-controller/latest/html/userguide/execution_environments.html)
- [Podman Documentation](https://docs.podman.io/)
- [Cluster API Documentation](https://cluster-api.sigs.k8s.io/)
- [vSphere Cloud Provider](https://github.com/kubernetes/cloud-provider-vsphere)
- [OpenShift Container Platform Documentation](https://docs.openshift.com/container-platform/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [YAML Lint Documentation](https://yamllint.readthedocs.io/)
- [Kubeval Documentation](https://www.kubeval.com/)

---

**Note**: This test environment provides a safe way to validate OpenShift cluster configurations before actual deployment. Always review generated manifests and test in a non-production environment first.