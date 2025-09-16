---

### `install_ansible_tools.sh`

```bash
#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# install_ansible_tools.sh
# Installs ansible-builder and ansible-navigator plus prerequisites on RHEL/Fedora.
# ---------------------------------------------------------------------------

set -euo pipefail

echo "==> Installing prerequisites..."
# Use dnf if available, otherwise yum
if command -v dnf >/dev/null 2>&1; then
    PKG_MGR="dnf"
else
    PKG_MGR="yum"
fi

sudo ${PKG_MGR} -y install python3 python3-pip podman git

echo "==> Upgrading pip..."
python3 -m pip install --upgrade pip wheel setuptools

echo "==> Installing ansible-builder and ansible-navigator via pip..."
python3 -m pip install --user "ansible-builder>=3.0.0" "ansible-navigator>=2.16.0"

# Add ~/.local/bin to PATH if not already
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo "export PATH=\$HOME/.local/bin:\$PATH" >> "$HOME/.bashrc"
    export PATH="$HOME/.local/bin:$PATH"
    echo "==> Added ~/.local/bin to PATH"
fi

echo "==> Checking versions..."
printf "\nansible-builder version:\n"
ansible-builder --version || echo "ansible-builder not found in PATH."

printf "\nansible-navigator version:\n"
ansible-navigator --version || echo "ansible-navigator not found in PATH."

printf "\npodman version:\n"
podman --version || echo "podman not installed or not in PATH."

echo -e "\n==> Installation complete. Log out/in or run 'source ~/.bashrc' to refresh your PATH if needed."
```

---

### How to Use

1. Save the script above as `install_ansible_tools.sh`.
2. Make it executable:

```bash
chmod +x install_ansible_tools.sh
```

3. Run it:

```bash
./install_ansible_tools.sh
```

---

### What It Does

* Installs **Python 3**, **pip**, **Podman**, and **Git**.
* Upgrades pip/setuptools.
* Installs **ansible-builder** ≥3.0 and **ansible-navigator** ≥2.16 to your `~/.local/bin`.
* Ensures `~/.local/bin` is in your PATH.
* Shows version checks at the end.

