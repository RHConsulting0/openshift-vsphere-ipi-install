# OpenShift Manifest Test Script

## Overview

The `00-test-manifest.sh` script is a comprehensive tool for testing OpenShift manifest generation in a controlled environment. It creates a clean test environment, copies the original install configuration, and generates OpenShift manifests using the execution environment container.

## Purpose

This script automates the creation and testing of OpenShift manifests for cluster installation. The manifests are YAML files that define the configuration of the OpenShift cluster, including networking, storage, and other platform resources. It provides a safe way to test manifest generation without affecting the main installation process.

## Key Features

- **Clean Test Environment**: Creates isolated test directories for manifest generation
- **Prerequisites Validation**: Checks for required files and execution environment
- **Multiple Execution Modes**: Normal, verbose, and dry-run modes
- **Container Integration**: Uses execution environment for consistent tooling
- **Comprehensive Logging**: Timestamped, color-coded output with verbose options
- **Error Handling**: Robust error checking with helpful error messages

## Prerequisites

### Required Software
- **Podman**: Container runtime for execution environment
- **Execution Environment**: `ocp-provision-ee:latest` image must be built
- **Source Configuration**: `../ansible/install-dir/install-config.yaml.orig` must exist

### Build Execution Environment
Before using this script, build the execution environment:

```bash
cd automation-ee/ocp-provision-ee/
./builder.sh
```

## Usage

### Basic Syntax
```bash
./00-test-manifest.sh [OPTIONS]
```

### Command-Line Options

| Option | Description |
|--------|-------------|
| `-h, --help` | Show comprehensive help information |
| `-v, --verbose` | Enable detailed logging output |
| `-d, --dry-run` | Show what would be done without executing |

### Examples

#### Show Help
```bash
./00-test-manifest.sh -h
./00-test-manifest.sh --help
```

#### Normal Execution
```bash
./00-test-manifest.sh
```

#### Verbose Output
```bash
./00-test-manifest.sh --verbose
```

#### Dry Run (Preview Mode)
```bash
./00-test-manifest.sh --dry-run
```

#### Combined Options
```bash
./00-test-manifest.sh --verbose --dry-run
```

## Script Workflow

### 1. Prerequisites Validation
- Checks for source `install-config.yaml.orig` file
- Verifies execution environment image exists
- Creates required test directories

### 2. Environment Setup
- Displays configuration information
- Lists source directory contents
- Creates/verifies test directory structure

### 3. Cleanup Phase
- Removes old manifest files from test directories:
  - `./install-dir/manifests/`
  - `./install-dir/openshift/`
  - `./install-dir/cluster-api/`

### 4. Configuration Copy
- Copies `install-config.yaml.orig` to test directory
- Preserves original configuration for testing

### 5. Manifest Generation
- Runs `openshift-install create manifests` in execution environment container
- Generates all required OpenShift manifests
- Uses proper volume mounting and permissions

### 6. Results Display
- Shows final manifest directory contents
- Confirms successful completion
- Provides summary of generated files

## Directory Structure

### Source Directory
```
../ansible/install-dir/
└── install-config.yaml.orig    # Source configuration file
```

### Test Directory (Created/Cleaned)
```
./install-dir/
├── install-config.yaml         # Copied configuration
├── manifests/                  # Generated manifests
│   ├── *.yaml
│   └── *.yml
├── openshift/                  # OpenShift-specific manifests
│   ├── *.yaml
│   └── *.yml
└── cluster-api/                # Cluster API manifests
    ├── *.yaml
    └── *.yml
```

## Container Integration

### Execution Environment Features
- **Base Image**: `registry.redhat.io/ansible-automation-platform-25/ee-supported-rhel9:latest`
- **Custom Image**: `ocp-provision-ee:latest`
- **Tools Included**:
  - OpenShift installer tools (openshift-install, oc, kubectl)
  - Helm v3.16.3
  - Kustomize v5.5.0
  - Policy Generator v1.15.0
  - Corporate certificates and configurations

### Container Execution
```bash
podman run --rm \
  --ipc=host \
  --user=root \
  --group-add=root \
  -v ./install-dir:/runner/project:Z \
  ocp-provision-ee:latest \
  openshift-install create manifests --dir=/runner/project
```

## Output and Logging

### Color-Coded Output
- **Yellow**: Actions in progress and informational messages
- **Green**: Successful operations and completion messages
- **Red**: Errors and failure conditions

### Logging Levels
- **Normal**: Standard progress messages with timestamps
- **Verbose**: Additional details about operations and file paths
- **Dry Run**: Preview of what would be executed

### Example Output
```
2024-10-01 18:30:15 Listing cluster provision install directory contents: [../ansible/install-dir]
2024-10-01 18:30:15 Cleaning up old manifests...
2024-10-01 18:30:15 Copying install-config.yaml.orig to install-dir...
2024-10-01 18:30:15 Creating OpenShift manifests...
2024-10-01 18:30:20 Manifests created successfully
2024-10-01 18:30:20 All steps completed successfully! 🎉
```

## Troubleshooting

### Common Issues

#### Missing Source Configuration
```
ERROR: Source install config not found: ../ansible/install-dir/install-config.yaml.orig
```
**Solution**: Ensure the cluster initialization process has created the original install config.

#### Missing Execution Environment
```
ERROR: Execution environment image 'ocp-provision-ee:latest' not found
```
**Solution**: Build the execution environment:
```bash
cd automation-ee/ocp-provision-ee/
./builder.sh
```

#### Permission Issues
**Solution**: Ensure Podman is running and has proper permissions for volume mounting.

### Debugging Tips
- Use `--verbose` option for detailed logging
- Use `--dry-run` to preview operations without executing
- Check Podman image list: `podman images | grep ocp-provision-ee`
- Verify source file exists: `ls -la ../ansible/install-dir/install-config.yaml.orig`

## Security Considerations

- **Container Isolation**: Runs in isolated container environment
- **Volume Mounting**: Uses SELinux context (`:Z`) for proper file access
- **Root Access**: Container runs as root for system-level operations
- **Network Access**: Container has full network access for API calls

## Best Practices

1. **Always validate prerequisites** before running the script
2. **Use dry-run mode** to preview operations before execution
3. **Check verbose output** for detailed operation information
4. **Review generated manifests** to ensure proper configuration
5. **Clean up test directories** after testing if needed

## Related Scripts

- `../ee-bash.sh`: Interactive execution environment launcher
- `../030-run-install-and-monitor.sh`: Full cluster installation
- `../040-run-install-gitops.sh`: GitOps operator installation
- `../automation-ee/ocp-provision-ee/builder.sh`: Build execution environment

## References

- [OpenShift Documentation: Creating a Cluster](https://docs.openshift.com/container-platform/latest/installing/index.html)
- [OpenShift Installer GitHub](https://github.com/openshift/installer)
- [Ansible Execution Environments](https://docs.ansible.com/automation-controller/latest/html/userguide/execution_environments.html)
- [Podman Documentation](https://docs.podman.io/)

