#!/bin/bash

# Clean up build environment - remove old images, containers, volumes, etc.
# Usage: ./clean-build-env.sh   
rm -rf ./context


podman system prune -a




