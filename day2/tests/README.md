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
- [CI/CD Integration](#-cicd-integration)
- [Performance Testing](#-performance-testing)
- [Contributing](#-contributing)
- [License](#-license)

## 🎯 Overview

The tests directory provides a comprehensive testing framework that ensures:

- **Configuration Validation**: All Kustomize and Helm configurations are valid
- **Resource Validation**: Kubernetes resources are properly defined
- **Dependency Validation**: All dependencies are satisfied
- **Build Validation**: All configurations build successfully
- **Integration Testing**: End-to-end testing of the GitOps system
- **Performance Testing**: Validate system performance under load
- **Security Testing**: Ensure configurations meet security standards

### Key Features

- **Automated Testing**: Fully automated test execution
- **Comprehensive Coverage**: Tests all components and configurations
- **Multiple Test Types**: Unit, integration, and performance tests
- **CI/CD Ready**: Designed for continuous integration pipelines
- **Detailed Reporting**: Comprehensive test results and logging
- **Easy Debugging**: Detailed error messages and troubleshooting guides

## 📁 Directory Structure

```
tests/
├── README.md                                    # This file
└── test-all-kustomization-builds-playbook.yaml  # Main test playbook
```

## 🧪 Test Types

### 1. Kustomize Build Validation

**Purpose**: Ensures all Kustomize configurations build successfully

**Test Coverage:**
- All `kustomization.yaml` files in the repository
- Base configurations in `capabilities/kustomize/bases/`
- Group configurations in `groups/kustomize/groups/`
- Cluster configurations in `clusters/`
- Application configurations in `applications/` (if present)

**Test Features:**
- Recursive discovery of kustomization files
- Helm support enabled (`--enable-helm`)
- Alpha plugins enabled (`--enable-alpha-plugins`)
- Environment variable support (`POLICY_GEN_ENABLE_HELM`)

**Test Command:**
```bash
# Run all kustomize builds
ansible-playbook test-all-kustomization-builds-playbook.yaml

# Run with verbose output
ansible-playbook test-all-kustomization-builds-playbook.yaml -vvv
```

### 2. Helm Chart Validation

**Purpose**: Validates Helm chart templates and values

**Test Coverage:**
- Chart syntax validation
- Template rendering with various values
- Values validation
- Dependency resolution
- Chart security scanning

**Test Commands:**
```bash
# Lint all Helm charts
find capabilities/helm/charts -name "Chart.yaml" -exec dirname {} \; | xargs -I {} helm lint {}

# Template all charts
find capabilities/helm/charts -name "Chart.yaml" -exec dirname {} \; | xargs -I {} helm template {} --dry-run

# Security scan
helm plugin install https://github.com/securecodewarrior/helm-security-scan
find capabilities/helm/charts -name "Chart.yaml" -exec dirname {} \; | xargs -I {} helm security-scan {}
```

### 3. Resource Validation

**Purpose**: Validates Kubernetes resource definitions

**Test Coverage:**
- Resource syntax validation
- Required fields validation
- Label consistency
- Annotation validation
- Resource naming conventions
- RBAC validation

**Test Commands:**
```bash
# Dry run validation
kustomize build . | oc apply --dry-run=client -f -

# Server-side validation
kustomize build . | oc apply --dry-run=server -f -

# Resource validation with kubeval
kustomize build . | kubeval --strict

# Resource validation with conftest
kustomize build . | conftest test -
```

### 4. Integration Testing

**Purpose**: End-to-end testing of the GitOps system

**Test Coverage:**
- ApplicationSet deployment
- Application synchronization
- Policy enforcement
- Resource creation and management
- ArgoCD application health
- ACM policy compliance

**Test Commands:**
```bash
# Deploy test configuration
kustomize build clusters/lab/ | oc apply -f -

# Verify ArgoCD applications
oc get applications -n openshift-gitops
oc get applicationsets -n openshift-gitops

# Check application health
oc get applications -n openshift-gitops -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.health.status}{"\n"}{end}'

# Verify ACM policies
oc get policies -A
oc get policyreports -A
```

### 5. Performance Testing

**Purpose**: Validates system performance under load

**Test Coverage:**
- Build time performance
- Resource usage during builds
- Memory consumption
- CPU usage patterns

**Test Commands:**
```bash
# Time kustomize builds
time kustomize build capabilities/kustomize/bases/openshift-gitops/

# Monitor resource usage
/usr/bin/time -v kustomize build clusters/lab/

# Profile memory usage
valgrind --tool=massif kustomize build clusters/lab/
```

### 6. Security Testing

**Purpose**: Ensures configurations meet security standards

**Test Coverage:**
- Security policy compliance
- RBAC validation
- Network policy validation
- Pod security standards
- Resource quotas and limits

**Test Commands:**
```bash
# Security scan with kube-score
kustomize build . | kube-score score -

# Security scan with kubeaudit
kustomize build . | kubeaudit all -

# Policy validation with OPA
kustomize build . | conftest test --policy security-policies/
```

## 🚀 Running Tests

### Prerequisites

- **Ansible 2.9+**: For running test playbooks
- **kustomize CLI**: For Kustomize build validation
- **helm CLI**: For Helm chart validation
- **oc CLI**: For OpenShift integration tests
- **kubeval**: For Kubernetes resource validation (optional)
- **conftest**: For policy validation (optional)
- **kube-score**: For security scoring (optional)

### Installation

```bash
# Install Ansible
pip install ansible

# Install kustomize
curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash

# Install helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install oc CLI
# Download from https://mirror.openshift.com/pub/openshift-v4/clients/oc/latest/

# Install additional tools (optional)
go install github.com/instrumenta/kubeval@latest
go install github.com/open-policy-agent/conftest@latest
go install github.com/zegl/kube-score@latest
```

### 1. Run All Tests

```bash
# Run comprehensive test suite
ansible-playbook test-all-kustomization-builds-playbook.yaml

# Run with verbose output
ansible-playbook test-all-kustomization-builds-playbook.yaml -vvv

# Run with specific verbosity level
ansible-playbook test-all-kustomization-builds-playbook.yaml -v
```

### 2. Run Specific Test Types

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

### 3. Test Specific Directories

```bash
# Test capabilities only
kustomize build capabilities/kustomize/bases/openshift-gitops/

# Test cluster groups only
kustomize build groups/kustomize/groups/hub/

# Test clusters only
kustomize build clusters/labhub/

# Test specific capability
kustomize build capabilities/kustomize/bases/acm-operator/
```

### 4. Test with Validation

```bash
# Test with OpenShift validation
kustomize build clusters/lab/ | oc apply --dry-run=client -f -

# Test with server-side validation
kustomize build clusters/labhub/ | oc apply --dry-run=server -f -

# Test with kubeval validation
kustomize build . | kubeval --strict

# Test with conftest policy validation
kustomize build . | conftest test -
```

### 5. Test with Different Environments

```bash
# Test with development environment
export ENVIRONMENT=dev
ansible-playbook test-all-kustomization-builds-playbook.yaml

# Test with production environment
export ENVIRONMENT=prod
ansible-playbook test-all-kustomization-builds-playbook.yaml

# Test with custom environment
export ENVIRONMENT=custom
ansible-playbook test-all-kustomization-builds-playbook.yaml
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
      loop_control:
        loop_var: kustomization_directory
      changed_when: false
      register: built_kustomizations

    - name: Print kustomize build output (enable -v to see)
      ansible.builtin.debug:
        msg: "{{ built_kustomization.stdout }}"
        verbosity: 1
      loop: "{{ built_kustomizations.results }}"
      loop_control:
        loop_var: built_kustomization
        label: "{{ built_kustomization.kustomization_directory }}"
```

### Test Environment Variables

```bash
# Enable Helm support
export POLICY_GEN_ENABLE_HELM=true

# Enable alpha plugins
export KUSTOMIZE_ENABLE_ALPHA_PLUGINS=true

# Set OpenShift context
export KUBECONFIG=/path/to/kubeconfig

# Set environment
export ENVIRONMENT=dev

# Enable debug mode
export DEBUG=true

# Set test timeout
export TEST_TIMEOUT=300
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

# Test only security
ansible-playbook test-all-kustomization-builds-playbook.yaml --tags security

# Test only performance
ansible-playbook test-all-kustomization-builds-playbook.yaml --tags performance
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
         
       - name: Validate new feature resources
         ansible.builtin.command:
           cmd: kustomize build new-feature/ | oc apply --dry-run=client -f -
         register: validation_result
         failed_when: validation_result.rc != 0
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
     
   - name: Security scan
     ansible.builtin.command:
       cmd: kustomize build . | kube-score score -
     register: security_test
     failed_when: security_test.rc != 0
   ```

3. **Test Changes**:
   ```bash
   ansible-playbook test-all-kustomization-builds-playbook.yaml
   ```

### Creating Test Suites

1. **Create Suite File**:
   ```bash
   touch tests/test-suite-security.yaml
   ```

2. **Define Suite**:
   ```yaml
   # test-suite-security.yaml
   - name: Security Test Suite
     hosts: localhost
     connection: local
     gather_facts: false
     tasks:
       - name: Run security tests
         include_tasks: security-tests.yaml
         tags: security
   ```

3. **Run Suite**:
   ```bash
   ansible-playbook test-suite-security.yaml
   ```

## 🚨 Troubleshooting

### Common Test Issues

1. **Kustomize Build Failures**
   ```bash
   # Check for missing resources
   kustomize build problematic-directory/
   
   # Verify resource references
   grep -r "kind:" problematic-directory/
   
   # Check for circular dependencies
   kustomize build problematic-directory/ --enable-helm
   ```

2. **Helm Chart Issues**
   ```bash
   # Validate chart syntax
   helm lint charts/chart-name/
   
   # Test chart rendering
   helm template charts/chart-name/
   
   # Check chart dependencies
   helm dependency list charts/chart-name/
   ```

3. **Resource Validation Failures**
   ```bash
   # Check resource syntax
   kustomize build . | oc apply --dry-run=client -f -
   
   # Check specific resources
   oc get -f resource-file.yaml --dry-run=client
   
   # Validate with kubeval
   kustomize build . | kubeval --strict
   ```

4. **Permission Issues**
   ```bash
   # Check OpenShift permissions
   oc auth can-i create applications -n openshift-gitops
   oc auth can-i update applications -n openshift-gitops
   
   # Check cluster access
   oc cluster-info
   oc get nodes
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

# OpenShift debug mode
oc apply --dry-run=client -f - --v=8
```

### Test Logs

Test logs provide detailed information about failures:

```bash
# Run tests with log output
ansible-playbook test-all-kustomization-builds-playbook.yaml -v

# Save test output to file
ansible-playbook test-all-kustomization-builds-playbook.yaml > test-output.log 2>&1

# Run tests with timestamp
ansible-playbook test-all-kustomization-builds-playbook.yaml -v | tee "test-$(date +%Y%m%d-%H%M%S).log"
```

### Performance Issues

```bash
# Profile kustomize builds
time kustomize build capabilities/kustomize/bases/openshift-gitops/

# Monitor resource usage
/usr/bin/time -v kustomize build clusters/lab/

# Check memory usage
ps aux | grep kustomize
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
- **Security**: All security policies are met
- **Performance**: Build times are within acceptable limits

### Test Failure Handling

- **Immediate Failure**: Stop on first failure (default)
- **Continue on Error**: Continue testing other configurations
- **Detailed Logging**: Provide detailed error information
- **Cleanup**: Clean up test resources
- **Reporting**: Generate comprehensive test reports

### Test Reports

```bash
# Generate test report
ansible-playbook test-all-kustomization-builds-playbook.yaml -v > test-report.txt

# Generate JSON report
ansible-playbook test-all-kustomization-builds-playbook.yaml -v | jq '.' > test-report.json

# Generate HTML report
ansible-playbook test-all-kustomization-builds-playbook.yaml -v | ansible-playbook-report > test-report.html
```

## 🔄 CI/CD Integration

### GitHub Actions

```yaml
# .github/workflows/test.yml
name: Test Configuration
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Install dependencies
        run: |
          pip install ansible
          curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash
      - name: Run tests
        run: ansible-playbook day2/tests/test-all-kustomization-builds-playbook.yaml
```

### GitLab CI

```yaml
# .gitlab-ci.yml
test:
  stage: test
  image: ubuntu:latest
  before_script:
    - apt-get update && apt-get install -y ansible python3-pip
    - pip3 install ansible
    - curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash
  script:
    - ansible-playbook day2/tests/test-all-kustomization-builds-playbook.yaml
```

### Jenkins Pipeline

```groovy
// Jenkinsfile
pipeline {
    agent any
    stages {
        stage('Test') {
            steps {
                sh 'pip install ansible'
                sh 'curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash'
                sh 'ansible-playbook day2/tests/test-all-kustomization-builds-playbook.yaml'
            }
        }
    }
}
```

## ⚡ Performance Testing

### Build Time Testing

```bash
# Time individual builds
time kustomize build capabilities/kustomize/bases/openshift-gitops/
time kustomize build clusters/labhub/
time kustomize build groups/kustomize/groups/hub/

# Profile build performance
kustomize build --enable-helm --enable-alpha-plugins clusters/lab/ | wc -l
```

### Memory Usage Testing

```bash
# Monitor memory usage
/usr/bin/time -v kustomize build clusters/lab/

# Profile memory with valgrind
valgrind --tool=massif kustomize build clusters/lab/

# Check memory consumption
ps aux | grep kustomize | awk '{print $6}' | sort -n
```

### Resource Validation Performance

```bash
# Time resource validation
time kustomize build . | oc apply --dry-run=client -f -

# Profile validation performance
kustomize build . | oc apply --dry-run=server -f - --v=8
```

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
   
   # Run specific tests
   ansible-playbook test-all-kustomization-builds-playbook.yaml --tags new-feature
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
- **Comments**: Add comments for complex test logic

### Test Guidelines

1. **Test Coverage**: Ensure comprehensive test coverage
2. **Test Isolation**: Tests should be independent
3. **Test Data**: Use realistic test data
4. **Test Cleanup**: Clean up test resources
5. **Test Documentation**: Document test purpose and usage

## 📄 License

This project is part of the ODFL OpenShift vSphere IPI Installation automation framework.

---

**Note**: Always run tests before committing changes to ensure configuration validity and system stability. For production deployments, run the full test suite including integration and performance tests.