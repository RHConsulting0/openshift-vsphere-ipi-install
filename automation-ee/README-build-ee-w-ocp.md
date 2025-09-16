---

## 1️⃣ `execution-environment.yml`

```yaml
version: 3
build_arg_defaults:
  EE_BASE_IMAGE: registry.redhat.io/ansible-automation-platform-25/ee-supported-rhel9:latest
  EE_BUILDER_IMAGE: registry.redhat.io/ansible-automation-platform-25/ansible-builder-rhel9:latest

dependencies:
  python:  # any python libs your playbooks need
    - openshift
    - kubernetes
    - pyyaml
  system:  # rpm/system packages installed by microdnf
    - tar
    - gzip
    - curl

additional_build_steps:
  prepend:
    - |
      # Install OpenShift installer + client
      INSTALLER_VERSION=4.18.0
      INSTALLER_URL="https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${INSTALLER_VERSION}/openshift-install-linux.tar.gz"
      CLIENT_URL="https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${INSTALLER_VERSION}/openshift-client-linux.tar.gz"

      microdnf update -y && microdnf install -y tar gzip curl && microdnf clean all

      curl -fSL "${INSTALLER_URL}" -o /tmp/openshift-install.tar.gz
      curl -fSL "${CLIENT_URL}" -o /tmp/openshift-client.tar.gz

      tar -C /usr/local/bin -xzf /tmp/openshift-install.tar.gz openshift-install
      tar -C /usr/local/bin -xzf /tmp/openshift-client.tar.gz oc kubectl

      chmod +x /usr/local/bin/openshift-install /usr/local/bin/oc /usr/local/bin/kubectl
      rm -rf /tmp/*.tar.gz
  append:
    - |
      # Default to bash for interactive debugging
      CMD ["/bin/bash"]
```

---

### How This Works

* **`EE_BASE_IMAGE`** sets your base EE image.
* Under **`dependencies.system`** we install `curl`, `tar`, `gzip`.
* In **`additional_build_steps.prepend`**, we download and install `openshift-install`, `oc`, and `kubectl`.
* **`CMD ["/bin/bash"]`** makes the container start with Bash by default.

---

## 2️⃣ Build the EE with ansible-builder

```bash
ansible-builder build -t my-ee-image:latest -f execution-environment.yml
```

This produces a container image called `my-ee-image:latest` with everything included.

---

## 3️⃣ Run Playbooks With ansible-navigator

Example:

```bash
ansible-navigator run playbooks/openshift-install.yml \
  --eei my-ee-image:latest \
  -m stdout
```

Or with Podman:

```bash
podman run --rm -it \
  -v $(pwd)/clusterconfig:/runner/project/clusterconfig:Z \
  -v $(pwd)/playbooks:/runner/project/playbooks:Z \
  -e KUBECONFIG=/runner/project/clusterconfig/auth/kubeconfig \
  my-ee-image:latest \
  ansible-playbook /runner/project/playbooks/openshift-install.yml
```

---

## 4️⃣ Benefits

* **Single reproducible EE** → no manual curl or installs later.
* All your **Python + system dependencies** and **CLI tools** in one container.
* Works seamlessly with `ansible-navigator` or `ansible-runner`.

---
