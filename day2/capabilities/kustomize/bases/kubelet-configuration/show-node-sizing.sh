#!/bin/bash

# Ensure you're logged into your OpenShift cluster with `oc login` before running the script.

# Fetch the list of nodes
nodes=$(oc get nodes -o name)

# Iterate through each node
for node in $nodes; do
  printf "NODE: $node \n"
  
  # Run a command to display the file's content on the node
  oc debug $node -- chroot /host cat /etc/node-sizing.env 2>/dev/null
  
  printf "=====\n"
done

