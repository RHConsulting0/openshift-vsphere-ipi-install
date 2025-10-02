#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Usage function
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

DESCRIPTION:
    Test OpenShift manifest generation using the install-config.yaml.orig file.
    This script creates a clean test environment, copies the original install config,
    and generates OpenShift manifests using the execution environment container.

WORKFLOW:
    1. Clean up old manifest files from test directories
    2. Copy install-config.yaml.orig to test install directory
    3. Generate OpenShift manifests using openshift-install
    4. Display success confirmation

DIRECTORIES:
    Source: ../ansible/install-dir/install-config.yaml.orig
    Test:   ./install-dir/ (created/cleaned automatically)
    Output: ./install-dir/manifests/, ./install-dir/openshift/, ./install-dir/cluster-api/

PREREQUISITES:
    - Podman must be installed and running
    - Execution environment image 'ocp-provision-ee:latest' must be built
    - Source install-config.yaml.orig must exist in ../ansible/install-dir/
    - Run './automation-ee/ocp-provision-ee/builder.sh' to build the EE image

CONTAINER FEATURES:
    - OpenShift installer tools (openshift-install, oc, kubectl)
    - Pre-configured with corporate certificates and configurations
    - Runs in isolated environment with proper permissions

OPTIONS:
    -h, --help    Show this help message
    -v, --verbose Enable verbose output (default: normal)
    -d, --dry-run Show what would be done without executing

EXAMPLES:
    $0                    # Run manifest generation test
    $0 --verbose         # Run with verbose output
    $0 --dry-run         # Show what would be done
    $0 -h                # Show this help

OUTPUT:
    - Cleaned manifest directories
    - Generated OpenShift manifests
    - Success confirmation with timestamp

TROUBLESHOOTING:
    - Ensure ../ansible/install-dir/install-config.yaml.orig exists
    - Verify execution environment image is built
    - Check Podman is running and accessible
    - Review log output for specific error messages

EOF
}

# Check for help option
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    usage
    exit 0
fi

# Parse command line options
VERBOSE=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        *)
            echo "ERROR: Unknown option '$1'"
            echo ""
            usage
            exit 1
            ;;
    esac
done

# Directories for manifests and test
INSTALL_DIR=../ansible/install-dir                # Directory containing install-config.yaml.orig

TEST_INSTALL_DIR=./install-dir
CLUSTER_API_DIR=$TEST_INSTALL_DIR/cluster-api
MANIFEST_DIR=$TEST_INSTALL_DIR/manifests
OPENSHIFT_DIR=$TEST_INSTALL_DIR/openshift

# Execution container
EXECUTION_CONTAINER="ocp-provision-ee:latest"

# Function to print messages with timestamp and color
log() {
    local color=$1
    local msg=$2
    printf "%s %b%s%b\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$color" "$msg" "$NC"
}

# Function for verbose logging
verbose_log() {
    if [[ "$VERBOSE" == "true" ]]; then
        log $YELLOW "VERBOSE: $1"
    fi
}

# Function for dry run
dry_run_log() {
    if [[ "$DRY_RUN" == "true" ]]; then
        log $YELLOW "DRY RUN: $1"
    fi
}

# Validate prerequisites
validate_prerequisites() {
    verbose_log "Validating prerequisites..."
    
    # Check if source install config exists
    if [ ! -f "$INSTALL_DIR/install-config.yaml.orig" ]; then
        log $RED "ERROR: Source install config not found: $INSTALL_DIR/install-config.yaml.orig"
        echo ""
        echo "Please ensure the install-config.yaml.orig file exists in the source directory."
        echo "This file should be created by the cluster initialization process."
        exit 1
    fi
    
    # Check if execution environment image exists
    if ! podman image exists "$EXECUTION_CONTAINER" 2>/dev/null; then
        log $RED "ERROR: Execution environment image '$EXECUTION_CONTAINER' not found"
        echo ""
        echo "To build the execution environment, run:"
        echo "  cd automation-ee/ocp-provision-ee/"
        echo "  ./builder.sh"
        echo ""
        exit 1
    fi
    
    verbose_log "Prerequisites validation passed"
}

# Create test directories if they don't exist
create_test_directories() {
    verbose_log "Creating test directories..."
    
    mkdir -p "$TEST_INSTALL_DIR"
    mkdir -p "$CLUSTER_API_DIR"
    mkdir -p "$MANIFEST_DIR"
    mkdir -p "$OPENSHIFT_DIR"
    
    verbose_log "Test directories created/verified"
}

# Display configuration information
show_configuration() {
    echo "=========================================="
    echo "OpenShift Manifest Test Configuration"
    echo "=========================================="
    echo "Source Install Config: $INSTALL_DIR/install-config.yaml.orig"
    echo "Test Install Directory: $TEST_INSTALL_DIR"
    echo "Execution Container: $EXECUTION_CONTAINER"
    echo "Verbose Mode: $VERBOSE"
    echo "Dry Run Mode: $DRY_RUN"
    echo "=========================================="
    echo ""
}

# Main execution starts here
main() {
    # Validate prerequisites first
    validate_prerequisites
    
    # Create test directories
    create_test_directories
    
    # Show configuration
    show_configuration
    
    # List source directory contents
    log $YELLOW "Listing cluster provision install directory contents: [${INSTALL_DIR}]"
    if [[ "$DRY_RUN" == "true" ]]; then
        dry_run_log "Would list contents of: $INSTALL_DIR"
    else
        ls -lta "$INSTALL_DIR"
    fi
    
    printf "\n"
    log $YELLOW "Cleaning up old manifests..."
    
    # Clean manifest directories
    if [[ "$DRY_RUN" == "true" ]]; then
        dry_run_log "Would clean manifest files from: $MANIFEST_DIR"
        dry_run_log "Would clean manifest files from: $OPENSHIFT_DIR"
        dry_run_log "Would clean manifest files from: $CLUSTER_API_DIR"
    else
        log $YELLOW "  Cleaning [${MANIFEST_DIR}]..."
        rm -fv $MANIFEST_DIR/*.yml 2>/dev/null || true
        rm -fv $MANIFEST_DIR/*.yaml 2>/dev/null || true
        
        log $YELLOW "  Cleaning [${OPENSHIFT_DIR}]..."
        rm -fv $OPENSHIFT_DIR/*.yaml 2>/dev/null || true
        rm -fv $OPENSHIFT_DIR/*.yml 2>/dev/null || true
        
        log $YELLOW "  Cleaning [${CLUSTER_API_DIR}]..."
        rm -fv $CLUSTER_API_DIR/*.yaml 2>/dev/null || true
        rm -fv $CLUSTER_API_DIR/*.yml 2>/dev/null || true
    fi
    
    printf "\n"
    log $YELLOW "Viewing [${TEST_INSTALL_DIR}]"
    if [[ "$DRY_RUN" == "true" ]]; then
        dry_run_log "Would list contents of: $TEST_INSTALL_DIR"
    else
        ls -ltaR $TEST_INSTALL_DIR
    fi
    printf "\n"
    log $GREEN "Old manifests cleaned up successfully"
    
    # Copy install config
    log $YELLOW "Copying install-config.yaml.orig to install-dir..."
    if [[ "$DRY_RUN" == "true" ]]; then
        dry_run_log "Would copy: $INSTALL_DIR/install-config.yaml.orig -> $TEST_INSTALL_DIR/install-config.yaml"
    else
        cp "$INSTALL_DIR/install-config.yaml.orig" "$TEST_INSTALL_DIR/install-config.yaml"
        verbose_log "Copied install config: $INSTALL_DIR/install-config.yaml.orig -> $TEST_INSTALL_DIR/install-config.yaml"
    fi
    log $GREEN "install-config.yaml copied successfully"
    
    # Create OpenShift manifests
    log $YELLOW "Creating OpenShift manifests..."
    if [[ "$DRY_RUN" == "true" ]]; then
        dry_run_log "Would run: podman run --rm --ipc=host --user=root --group-add=root -v $TEST_INSTALL_DIR:/runner/project:Z $EXECUTION_CONTAINER openshift-install create manifests --dir=/runner/project"
    else
        log $YELLOW "  Podman container starting...\n"
        verbose_log "Running openshift-install create manifests in container"
        podman run --rm \
          --ipc=host \
          --user=root \
          --group-add=root \
          -v "$TEST_INSTALL_DIR:/runner/project:Z" \
          "$EXECUTION_CONTAINER" openshift-install create manifests --dir=/runner/project
    fi
    
    log $GREEN "Manifests created successfully"
    
    # Show final results
    if [[ "$DRY_RUN" == "false" ]]; then
        printf "\n"
        log $YELLOW "Final manifest directory contents:"
        ls -ltaR $TEST_INSTALL_DIR
    fi
    
    printf "\n"
    log $GREEN "All steps completed successfully! 🎉"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log $YELLOW "DRY RUN COMPLETE - No actual changes were made"
    fi
}

# Run main function
main
