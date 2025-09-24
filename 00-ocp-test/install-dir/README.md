# install-dir

Purpose
- This directory is the target working directory used by the OpenShift installer (`openshift-install --dir=<install-dir> ...`).
- It holds the cluster's `install-config.yaml` and the generated artifacts/manifests the installer produces (manifests, ignition configs, metadata, auth, etc.).

Typical contents
- install-config.yaml — cluster configuration used by the installer.
- manifests/ — generated Kubernetes/OpenShift manifests (and any user-managed overrides).
- auth/ — credentials and bootstrap auth artifacts created during install.
- kubeconfig / kubeadmin-password — created post-install (on success).
- metadata.json — installer metadata for the cluster.
- *.ign / openshift/ — ignition and other generated assets.

Basic workflow
1. Prepare or copy a validated install-config.yaml into this directory.
2. Generate manifests (to review/patch operator manifests before provisioning):
   ```bash
   openshift-install create manifests --dir=/path/to/install-dir
   ```
3. (Optional) Generate ignition configs for manual provisioning / debugging:
   ```bash
   openshift-install create ignition-configs --dir=/path/to/install-dir
   ```
4. Create the cluster (for assisted/IPI flows; this will attempt to provision resources):
   ```bash
   openshift-install create cluster --dir=/path/to/install-dir
   ```
5. After successful install, inspect `auth/`, `kubeconfig`, and `metadata.json`.

Tips & validation
- Validate YAML and manifests before applying:
  - yamllint: `yamllint install-dir/manifests`
  - kubeval (optional): `kubeval --exit-status install-dir/manifests/*.yaml`
- Keep a copy of the original `install-config.yaml` in source control (sensitive data like pull secrets should be redacted).
- When patching manifests, keep changes in source control and document why the override is required.

Security
- Do not commit pull secrets, passwords, or private keys to public repositories.
- Use vaults or CI secrets for sensitive values; keep only templated or redacted `install-config.yaml` in repo.

Examples
- Render manifests from a template or prepared `install-config.yaml`:
  ```bash
  cp ../templates/install-config.yaml.j2 ./install-config.yaml   # if you render outside this dir
  openshift-install create manifests --dir=./install-dir
  ```

References
- OpenShift Installer docs: https://docs.openshift.com/container-platform/latest/installing/index.html
- OpenShift Installer GitHub: https://github.com/openshift/installer
