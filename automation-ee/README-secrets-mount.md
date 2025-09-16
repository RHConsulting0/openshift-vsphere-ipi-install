---

## 1️⃣ Directory Layout on the Host

```
my-project/
├─ clusterconfig/                # all cluster config
│  ├─ install-config.yaml
│  ├─ pull-secret.json
│  └─ ssh-private-key
└─ playbooks/
   └─ openshift-install.yml
```

We’ll mount `clusterconfig` into `/runner/project/clusterconfig` inside the EE.

---

## 2️⃣ Mount Secrets Into the EE Container

If you’re running your EE with **Podman**:

```bash
podman run --rm -it \
  -v $(pwd)/clusterconfig:/runner/project/clusterconfig:Z \
  -v $(pwd)/playbooks:/runner/project/playbooks:Z \
  -e KUBECONFIG=/runner/project/clusterconfig/auth/kubeconfig \
  my-ee-image \
  ansible-playbook /runner/project/playbooks/openshift-install.yml
```

### Breakdown:

* `-v $(pwd)/clusterconfig:/runner/project/clusterconfig:Z`
  Mounts your configs, pull secret, and SSH key.
* `-v $(pwd)/playbooks:/runner/project/playbooks:Z`
  Mounts your playbooks.
* `-e KUBECONFIG=...`
  Ensures any Ansible or `oc` commands know where kubeconfig lives.
* SELinux `:Z` keeps permissions correct on RHEL/Fedora/Podman hosts.

---

## 3️⃣ Tell `openshift-install` About the Pull Secret & SSH Key

Two options:

* **Already in `install-config.yaml`:**
  Put the pull secret and SSH public key fields there.
  Example snippet in `install-config.yaml`:

  ```yaml
  pullSecret: >
    {"auths":{"cloud.openshift.com":{...}}}
  sshKey: |
    ssh-rsa AAAAB3... user@host
  ```

* **Or mount the files separately** and reference them in a task if you generate `install-config.yaml` dynamically.

Because we’re mounting the entire directory, `openshift-install` automatically sees everything it expects in `--dir /runner/project/clusterconfig`.

---

## 4️⃣ Example Combined Command

This runs your playbook (which calls `openshift-install`) in one shot:

```bash
podman run --rm -it \
  -v $(pwd)/clusterconfig:/runner/project/clusterconfig:Z \
  -v $(pwd)/playbooks:/runner/project/playbooks:Z \
  -e KUBECONFIG=/runner/project/clusterconfig/auth/kubeconfig \
  my-ee-image \
  ansible-playbook /runner/project/playbooks/openshift-install.yml \
  -e install_dir=/runner/project/clusterconfig
```

---

## 5️⃣ Using ansible-navigator

If you’re using **ansible-navigator**, put this in `ansible-navigator.yml`:

```yaml
---
ansible-navigator:
  execution-environment:
    image: my-ee-image
    volume-mounts:
      - src: ./clusterconfig
        dest: /runner/project/clusterconfig
        options: Z
      - src: ./playbooks
        dest: /runner/project/playbooks
        options: Z
    environment-variables:
      - KUBECONFIG: /runner/project/clusterconfig/auth/kubeconfig
```

Then run:

```bash
ansible-navigator run playbooks/openshift-install.yml -m stdout
```

---

## 6️⃣ Security Notes

* The pull secret and SSH private key are sensitive. Keep them on a secure host or use Ansible Vault to encrypt them and decrypt inside the EE.
* Podman’s `:Z` mount option relabels for SELinux.
* Use minimal privileges and ephemeral containers whenever possible.

---

### ✅ TL;DR

Mount your `clusterconfig` directory and playbooks into the EE container with Podman or ansible-navigator. Put the pull secret and SSH public key in `install-config.yaml`. `openshift-install` will find everything automatically.

---
