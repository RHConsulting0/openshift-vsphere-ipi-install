# Command to execute
kustomize build --enable-helm . | oc apply -f-