#!/bin/bash

# Reference: https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/installing_on_vmware_vsphere/installer-provisioned-infrastructure#ssh-agent-using_ipi-vsphere-preparing-to-install

SSH_KEY_ED25519="id_ed25519_odfl"
SSH_KEY_RSA="id_rsa_odfl"

# Generate SSH keys if they don't exist
# Generate both ED25519 and RSA keys in the secrets folder

# ED25519 algorithm
ssh-keygen -t ed25519 -N '' -f $SSH_KEY_ED25519 
chmod 600 $SSH_KEY_ED25519
chmod 644 $SSH_KEY_ED25519.pub
cp $SSH_KEY_ED25519* ~/.ssh
# Legacy 
ssh-keygen -t rsa -b 4096 -N '' -f $SSH_KEY_RSA
chmod 600 $SSH_KEY_RSA
chmod 644 $SSH_KEY_RSA.pub
cp $SH_KEY_RSA* ~/.ssh


