# OpenShift Install Manifests Script

## Purpose

This script is used to automate the creation of OpenShift manifests for a cluster installation. The manifests are YAML files that define the configuration of the OpenShift cluster, including networking, storage, and other platform resources.

The key command used in this script is:

```bash
openshift-install create manifests --dir=<directory>
````

### `openshift-install create manifests`

* **Description:** Generates the initial OpenShift manifests based on the `install-config.yaml` file located in the specified directory.
* **Purpose:** Provides the foundation for the cluster by creating the Kubernetes and OpenShift resource definitions before the cluster is deployed.
* **Input:**

  * `install-config.yaml` – Contains cluster configuration such as platform, networking, pull secrets, and cluster name.
* **Output:**

  * A set of YAML manifests inside the specified directory, including core OpenShift resources, operator configurations, and network definitions.

### Script Workflow

1. **List installation directory contents:**
   Displays the files in the installation directory for verification.

2. **Copy the original `install-config.yaml`:**
   Ensures the script works with a clean copy of the configuration file.

3. **Create OpenShift manifests:**
   Runs the `openshift-install create manifests` command to generate all required manifests.

4. **Success confirmation:**
   Logs success messages with timestamps and color-coded output for easier debugging.

### Requirements

* OpenShift Installer (`openshift-install`) installed and accessible in `$PATH`.
* A valid `install-config.yaml` in the installation directory.
* Bash shell (`#!/bin/bash`) to execute the script.

### Example Usage

```bash
./create-manifests.sh
```

The script will produce a set of manifests in the `install-dir` directory and print step-by-step logs with timestamps.

### Notes

* The script uses colored output for better visibility:

  * Yellow for actions in progress.
  * Green for successful steps.
  * Red for failures (if any occur).
* The script will exit immediately if any command fails (`set -e`), ensuring early detection of errors.
* All logs are timestamped to track the execution time of each step.

### References

* [OpenShift Documentation: Creating a Cluster](https://docs.openshift.com/container-platform/latest/installing/index.html)
* [OpenShift Installer GitHub](https://github.com/openshift/installer)

