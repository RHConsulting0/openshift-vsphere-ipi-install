#!/bin/bash

# Reference: https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/installing_on_vmware_vsphere/installer-provisioned-infrastructure#ssh-agent-using_ipi-vsphere-preparing-to-install

# SSH Key Generation for OpenShift Container Platform deployment

SSH_KEY_ED25519="id_ed25519_odfl"
SSH_KEY_RSA="id_rsa_odfl"

# Show usage if help requested
show_usage() {
    echo "Usage: $0"
    echo ""
    echo "Generates SSH key pairs for OpenShift Container Platform deployment"
    echo ""
    echo "Generated keys:"
    echo "  • Ed25519: $SSH_KEY_ED25519 (recommended)"
    echo "  • RSA 4096: $SSH_KEY_RSA (legacy support)"
    echo ""
    echo "Keys are created without passphrases and copied to ~/.ssh/"
    echo "Use -h, --help, or help for detailed information"
}

case "${1:-}" in
    -h|--help|help)
        show_usage
        exit 0
        ;;
esac

echo "Generating SSH keys for OpenShift deployment..."

# Generate SSH keys if they don't exist
# Generate both ED25519 and RSA keys in the secrets folder

echo "Generating Ed25519 key pair..."
# ED25519 algorithm (recommended)
ssh-keygen -t ed25519 -N '' -f $SSH_KEY_ED25519 
chmod 600 $SSH_KEY_ED25519
chmod 644 $SSH_KEY_ED25519.pub

echo "Generating RSA 4096-bit key pair..."
# Legacy RSA for compatibility
ssh-keygen -t rsa -b 4096 -N '' -f $SSH_KEY_RSA
chmod 600 $SSH_KEY_RSA
chmod 644 $SSH_KEY_RSA.pub

echo "Copying keys to ~/.ssh directory..."
# Create ~/.ssh directory if it doesn't exist
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Copy keys to ~/.ssh (FIXED: was $SH_KEY_RSA, now $SSH_KEY_RSA)
cp $SSH_KEY_ED25519* ~/.ssh/
cp $SSH_KEY_RSA* ~/.ssh/

echo "SSH key generation completed successfully!"
echo ""
echo "Generated keys:"
echo "  Ed25519 private: $SSH_KEY_ED25519"
echo "  Ed25519 public:  $SSH_KEY_ED25519.pub"
echo "  RSA private:     $SSH_KEY_RSA"
echo "  RSA public:      $SSH_KEY_RSA.pub"
echo ""
echo "Keys have been copied to ~/.ssh/ directory"
echo ""
echo "To use with OpenShift, copy the public key content:"
echo "  cat $SSH_KEY_ED25519.pub"

