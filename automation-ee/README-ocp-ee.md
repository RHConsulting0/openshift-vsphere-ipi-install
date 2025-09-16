---

### 🔹 1. Ansible EE Is Just a Container

An EE is an OCI image built with **ansible-builder**.
It’s essentially a container with:

* Ansible Core
* Any collections you specify
* Any system or Python packages you install

Because of that, you can put **any binary you want** inside (including `openshift-install`) as long as it’s compatible with the base OS.

---

### 🔹 2. Add `openshift-install` During EE Build

In your `execution-environment.yml` add to `additional_build_steps`:

```yaml
version: 1
build_arg_defaults:
  EE_BASE_IMAGE: 'registry.redhat.io/ansible-automation-platform-25/ee-supported-rhel9:latest'

additional_build_steps:
  append:
    - RUN curl -L https://mirror.openshift.com/pub/openshift-v4/clients/ocp/4.18.0/openshift-install-linux.tar.gz \
      -o /tmp/openshift-install.tar.gz \
      && tar -C /usr/local/bin -xzf /tmp/openshift-install.tar.gz openshift-install \
      && chmod +x /usr/local/bin/openshift-install \
      && rm -f /tmp/openshift-install.tar.gz
```

This puts `openshift-install` into `/usr/local/bin` in the EE so it’s on `PATH`.

---

### 🔹 3. Invoke It Inside the EE

When running Navigator or Runner or Podman:

```bash
podman run -it \
  -v $(pwd):/runner/project:Z \
  my-ee-image \
  openshift-install create cluster --dir /runner/project/clusterconfig
```

or from a playbook task:

```yaml
- name: Run openshift-install
  ansible.builtin.command:
    cmd: openshift-install create cluster --dir /runner/project/clusterconfig
```

Because it’s on `PATH` inside the EE, it just works.

---

### 🔹 4. Things to Watch Out For

* **Binary size:** `openshift-install` is \~200+ MB uncompressed; your EE will grow accordingly.
* **Permissions:** Make sure you mount any kubeconfig, pull-secret, or SSH keys into the container with correct SELinux context (`:Z` for Podman).
* **Networking:** The EE container must have network access to reach cloud APIs or vSphere endpoints if you’re running IPI.
* **Long-running:** Installer can take a while; ensure your EE execution mechanism doesn’t kill long processes.

---

### 🔹 5. Recommended Pattern

Instead of shipping the binary in every EE, you can:

* Mount the binary from the host into the container at runtime, or
* Use a very thin EE plus a sidecar container with `openshift-install`.

But if you want **repeatability and portability**, building `openshift-install` into the EE is simplest.

---

### ✅ TL;DR

* **Yes you can run `openshift-install` in an Ansible EE.**
* **Install it into the EE image** (with `curl` + `tar` in `additional_build_steps`).
* **Then call it in your playbooks** or with `ansible-navigator run`.

---