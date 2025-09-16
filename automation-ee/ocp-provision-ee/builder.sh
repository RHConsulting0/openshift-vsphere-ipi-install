#!/bin/bash
###
# This script launches the AAP EE container environment for processing ansible playbooks.
# Prerequisites installed:
#      Podman
#      Ansible-builder
###

startTs=$(date +"%c")
printf ">>>> Build start @ $startTs <<<<\n" 
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
startTs=$SECONDS
ansible-builder build -t ocp-provision-ee:latest -v 3 --prune-images
endTs=$(date +"%c")
printf ">>>> Build end @ $endTs <<<<\n\n" 
elapsed=$(( SECONDS - startTs ))
eval "echo !!Elapsed time!!: $(date -ud "@$elapsed" +'$((%s/3600/24)) days %H hr %M min %S sec')"



