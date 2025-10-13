# Tests - Validation and Testing Framework

This directory contains comprehensive testing and validation tools for the Day2 Operations GitOps configuration management system.

## 📋 Table of Contents

- [Overview](#-overview)
- [Directory Structure](#-directory-structure)
- [Test Types](#-test-types)
- [Running Tests](#-running-tests)
- [Test Configuration](#️-test-configuration)
- [Customizing Tests](#-customizing-tests)
- [Troubleshooting](#-troubleshooting)
- [Test Results](#-test-results)
- [Contributing](#-contributing)
- [License](#-license)

## 🎯 Overview

The tests directory provides a comprehensive testing framework that ensures:

- **Configuration Validation**: All Kustomize and Helm configurations are valid
- **Resource Validation**: Kubernetes resources are properly defined
- **Dependency Validation**: All dependencies are satisfied
- **Build Validation**: All configurations build successfully
- **Integration Testing**: End-to-end testing of the GitOps system

## 📁 Directory Structure

```
tests/
├── README.md                           # This file
└── test-all-kustomization-builds-playbook.yaml  # Main test playbook
```

## 🧪 Test Types

### 1. Kustomize Build Validation

**Purpose**: Ensures all Kustomize configurations build successfully

**Test Coverage:**
- All `kustomization.yaml` files
- Base configurations in `capabilities/kustomize/bases/`
- Group configurations in `cluster-groups/kustomize/groups/`
- Cluster configurations in `clusters/`
- Tenant configurations in `tenants/`

**Test Command:**
```bash
ansible-playbook test-all-kustomization-builds-playbook.yaml
```

### 2. Helm Chart Validation

**Purpose**: Validates Helm chart templates and values

**Test Coverage:**
- Chart syntax validation
- Template rendering
- Values validation
- Dependency resolution

**Test Command:**
```bash
helm lint capabilities/helm/charts/*/
helm template capabilities/helm/charts/*/
```

### 3. Resource Validation

**Purpose**: Validates Kubernetes resource definitions

**Test Coverage:**
- Resource syntax validation
- Required fields validation
- Label consistency
- Annotation validation

**Test Command:**
```bash
kustomize build . | oc apply --dry-run=client -f -
```

### 4. Integration Testing

**Purpose**: End-to-end testing of the GitOps system

**Test Coverage:**
- ApplicationSet deployment
- Application synchronization
- Policy enforcement
- Resource creation

**Test Command:**
```bash
# Deploy test configuration
kustomize build clusters/lab/ | oc apply -f -

# Verify deployment
oc get applications -n openshift-gitops
oc get applicationsets -n openshift-gitops
```

## 🚀 Running Tests

### Prerequisites

- Ansible 2.9+
- `kustomize` CLI tool
- `helm` CLI tool
- `oc` CLI tool (for OpenShift)
- Access to OpenShift cluster (for integration tests)

### 1. Run All Tests

```bash
# Run comprehensive test suite
ansible-playbook test-all-kustomization-builds-playbook.yaml

# Run with verbose output
ansible-playbook test-all-kustomization-builds-playbook.yaml -vvv
```

### 2. Run Specific Test Types

```bash
# Test only Kustomize builds
ansible-playbook test-all-kustomization-builds-playbook.yaml --tags kustomize

# Test only Helm charts
ansible-playbook test-all-kustomization-builds-playbook.yaml --tags helm

# Test only resource validation
ansible-playbook test-all-kustomization-builds-playbook.yaml --tags resources
```

### 3. Test Specific Directories

```bash
# Test capabilities only
kustomize build capabilities/kustomize/bases/openshift-gitops/

# Test cluster groups only
kustomize build cluster-groups/kustomize/groups/hub-lab/

# Test clusters only
kustomize build clusters/hub-lab/

# Test tenants only
kustomize build tenants/clusters/example-tenant/
```

### 4. Test with Validation

```bash
# Test with OpenShift validation
kustomize build clusters/lab/ | oc apply --dry-run=client -f -

# Test with server-side validation
kustomize build clusters/hub-lab/ | oc apply --dry-run=server -f -
```

## ⚙️ Test Configuration

### Test Playbook Configuration

The main test playbook (`test-all-kustomization-builds-playbook.yaml`) includes:

```yaml
- name: Test all kustomization builds
  hosts: localhost
  connection: local
  gather_facts: false
  tasks:
    - name: Recursively find kustomization files to test
      ansible.builtin.find:
        paths: ../
        patterns:
          - kustomization.yaml
        contains: 'kind: Kustomization'
        read_whole_file: true
        recurse: true
      register: kustomization_files

    - name: Get kustomization directories to test
      ansible.builtin.set_fact:
        kustomization_directories: "{{ kustomization_files.files | map(attribute='path') | map('dirname') | list }}"

    - name: Test kustomize build of each kustomization directory
      ansible.builtin.command:
        argv:
          - kustomize
          - build
          - --enable-helm
          - --enable-alpha-plugins
          - "{{ kustomization_directory }}"
      environment:
        POLICY_GEN_ENABLE_HELM: "true"
      loop: "{{ kustomization_directories }}"
```

### Test Environment Variables

```bash
# Enable Helm support
export POLICY_GEN_ENABLE_HELM=true

# Enable alpha plugins
export KUSTOMIZE_ENABLE_ALPHA_PLUGINS=true

# Set OpenShift context
export KUBECONFIG=/path/to/kubeconfig
```

### Test Tags

The test playbook supports tags for selective testing:

```bash
# Test only Kustomize builds
ansible-playbook test-all-kustomization-builds-playbook.yaml --tags kustomize

# Test only Helm charts
ansible-playbook test-all-kustomization-builds-playbook.yaml --tags helm

# Test only resource validation
ansible-playbook test-all-kustomization-builds-playbook.yaml --tags resources

# Test only integration
ansible-playbook test-all-kustomization-builds-playbook.yaml --tags integration
```

## 🔧 Customizing Tests

### Adding New Test Cases

1. **Create Test File**:
   ```bash
   # Create new test file
   touch tests/test-new-feature.yaml
   ```

2. **Define Test Cases**:
   ```yaml
   # test-new-feature.yaml
   - name: Test new feature
     hosts: localhost
     connection: local
     gather_facts: false
     tasks:
       - name: Test new feature configuration
         ansible.builtin.command:
           cmd: kustomize build new-feature/
         register: test_result
         failed_when: test_result.rc != 0
   ```

3. **Add to Main Test Suite**:
   ```yaml
   # Include in main test playbook
   - import_playbook: test-new-feature.yaml
     tags: new-feature
   ```

### Modifying Existing Tests

1. **Edit Test Configuration**:
   ```bash
   vim tests/test-all-kustomization-builds-playbook.yaml
   ```

2. **Add New Test Steps**:
   ```yaml
   - name: Additional test step
     ansible.builtin.command:
       cmd: helm lint charts/
     register: helm_test
     failed_when: helm_test.rc != 0
   ```

3. **Test Changes**:
   ```bash
   ansible-playbook test-all-kustomization-builds-playbook.yaml
   ```

## 🚨 Troubleshooting

### Common Test Issues

1. **Kustomize Build Failures**
   ```bash
   # Check for missing resources
   kustomize build problematic-directory/
   
   # Verify resource references
   grep -r "kind:" problematic-directory/
   ```

2. **Helm Chart Issues**
   ```bash
   # Validate chart syntax
   helm lint charts/chart-name/
   
   # Test chart rendering
   helm template charts/chart-name/
   ```

3. **Resource Validation Failures**
   ```bash
   # Check resource syntax
   kustomize build . | oc apply --dry-run=client -f -
   
   # Check specific resources
   oc get -f resource-file.yaml --dry-run=client
   ```

### Debug Mode

Enable debug mode for detailed troubleshooting:

```bash
# Ansible debug mode
ansible-playbook test-all-kustomization-builds-playbook.yaml -vvv

# Kustomize debug mode
kustomize build --enable-helm --enable-alpha-plugins directory/

# Helm debug mode
helm template chart-name/ --debug --dry-run
```

### Test Logs

Test logs provide detailed information about failures:

```bash
# Run tests with log output
ansible-playbook test-all-kustomization-builds-playbook.yaml -v

# Save test output to file
ansible-playbook test-all-kustomization-builds-playbook.yaml > test-output.log 2>&1
```

## 📊 Test Results

### Test Output Format

The test playbook provides detailed output:

```
TASK [Test kustomize build of each kustomization directory] *******************
ok: [localhost] => (item=/path/to/directory1)
ok: [localhost] => (item=/path/to/directory2)
failed: [localhost] => (item=/path/to/directory3)
```

### Test Success Criteria

- **Kustomize Builds**: All configurations build successfully
- **Helm Charts**: All charts validate and render correctly
- **Resources**: All resources are valid Kubernetes objects
- **Dependencies**: All dependencies are satisfied

### Test Failure Handling

- **Immediate Failure**: Stop on first failure
- **Continue on Error**: Continue testing other configurations
- **Detailed Logging**: Provide detailed error information
- **Cleanup**: Clean up test resources

## 🤝 Contributing

### Development Workflow

1. **Create Feature Branch**:
   ```bash
   git checkout -b feature/new-tests
   ```

2. **Add Test Cases**:
   - Add new test files
   - Modify existing tests
   - Update documentation

3. **Test Changes**:
   ```bash
   # Run all tests
   ansible-playbook test-all-kustomization-builds-playbook.yaml
   ```

4. **Create Pull Request**:
   - Include description of changes
   - Reference any related issues
   - Ensure all tests pass

### Code Standards

- **Test Naming**: Use descriptive test names
- **Documentation**: Include README.md for new tests
- **Error Handling**: Include proper error handling
- **Logging**: Provide detailed logging output

## 📄 License

This project is part of the ODFL OpenShift vSphere IPI Installation automation framework.

---

**Note**: Always run tests before committing changes to ensure configuration validity and system stability.