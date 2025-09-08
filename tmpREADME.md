### Podman execution use of AEE environment

Minimal verbosity
```sh
podman run --rm -v $(pwd):/runner/project:Z -v ~/.ansible:/home/runner/.ansible:Z registry.redhat.io/ansible-automation-platform-25/ee-supported-rhel9:latest ansible-playbook -v /runner/project/populate-webserver.yml
```

Debug verbosity
```sh
podman run --rm -v $(pwd):/runner/project:Z -v ~/.ansible:/home/runner/.ansible:Z registry.redhat.io/ansible-automation-platform-25/ee-supported-rhel9:latest ansible-playbook -vvvv /runner/project/populate-webserver.yml
```


```sh
podman run --rm -v $(pwd):/runner/project:Z -v ~/.ansible:/home/runner/.ansible:Z registry.redhat.io/ansible-automation-platform-25/ee-supported-rhel9:latest ansible-playbook -i inventory \
-e @./group_vars/cluster/[cluster]/all.yaml \
-e @./group_vars/env/[env]/default-vault.yaml \
-e @./group_vars/env/[env]/all.yaml \
-e @./secrets/pull_secret.json \
-e @./group_vars/cluster/[cluster]/ssh-key.yaml \
--vault-password-file=../resources/vault-password.txt \
-vvvv /runner/project/initialize_cluster.yaml
```

```sh
ansible-playbook -i inventory \
-e @./group_vars/cluster/[cluster]/all.yaml \
-e @./group_vars/env/[env]/default-vault.yaml \
-e @./group_vars/env/[env]/all.yaml \
-e @./secrets/pull_secret.json \
-e @./group_vars/cluster/[cluster]/ssh-key.yaml \
--vault-password-file=../resources/vault-password.txt \
initialize_cluster.yaml
```

