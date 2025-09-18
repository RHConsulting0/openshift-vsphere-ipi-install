#!/bin/bash
###
# This script launches the AAP EE container environment for processing ansible playbooks.
# Prerequisites installed:
#      Podman
#      Ansible-builder
###

BASE_DIR=/home/miryan/Documents/projects/odfl/repos/openshift-vsphere-ipi-install/automation-ee
PAH=pah.client.example.com
EE_NAME=ocp-provision-ee
EE_VERSION=1.0
EE_VERBOSITY=3

# Cache the base image to localhost
podman pull registry.redhat.io/ansible-automation-platform-25/ee-supported-rhel9:latest
# podman pull registry.redhat.io/ansible-automation-platform-25/ee-minimal-rhel9:latest

cd ${BASE_DIR}${EE_NAME}
rm -rf context &> /dev/null

# Build start
startTs=$(date +"%c")
printf ">>>> Build start @ $startTs <<<<\n" 
startTs=$SECONDS

podman pull registry.redhat.io/ansible-automation-platform-25/ee-supported-rhel9:latest
# podman pull registry.redhat.io/ansible-automation-platform-25/ee-minimal-rhel9:latest

cd ${BASE_DIR}${EE_NAME}

# Clean the context directory
rm -rf context &> /dev/null

ansible-builder build --verbosity ${EE_VERBOSITY} --prune-images --tag ${EE_NAME}:${EE_VERSION} --tag ${EE_NAME}:latest

# Build complete
endTs=$(date +"%c")
printf ">>>> Build end @ $endTs <<<<\n\n" 
elapsed=$(( SECONDS - startTs ))
eval "echo !!Elapsed time!!: $(date -ud "@$elapsed" +'$((%s/3600/24)) days %H hr %M min %S sec')"

# Push to a Private Automation Hub (PAH)
# if [ $? -eq 0 ] ; then
#   podman push localhost/${EE_NAME}:latest docker://${PAH}/${EE_NAME}:${EE_VERSION}
#   podman push localhost/${EE_NAME}:latest docker://${PAH}/${EE_NAME}:latest
# fi

# Export EE image in tar file
# podman save --output ${EE_NAME}-${EE_VERSION}.tar localhost/${EE_NAME}:${EE_VERSION}
# gzip ${EE_NAME}-${EE_VERSION}.tar

# Clean the context directory
rm -rf context &> /dev/null



