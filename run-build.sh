#!/bin/bash
set -e

# Function to check if we're running as root
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "This script is not being run as root."
        echo "Checking directory permissions..."
        return 1
    fi
    return 0
}

# Function to check and fix permissions
check_and_fix_permissions() {
    local current_user=$(whoami)
    
    # Check if config_space directory exists and fix permissions if needed
    if [ -d "config_space" ]; then
        if [ ! -w "config_space" ]; then
            echo "The config_space directory is not writable by the current user."
            echo "Attempting to fix permissions..."
            
            if check_root; then
                # We're running as root, so we can fix permissions directly
                chown -R "$current_user:$current_user" .
                echo "Permissions fixed."
            else
                # We're not root, so we need to use sudo
                echo "Fixing permissions requires sudo access."
                sudo chown -R "$current_user:$current_user" .
                echo "Permissions fixed."
            fi
        fi
    fi
    
    # Create a test file to verify write permissions
    local test_dir="config_space/test_permissions"
    if ! mkdir -p "$test_dir" 2>/dev/null; then
        echo "Still unable to create directories in config_space."
        echo "Please run this script with sudo or fix permissions manually:"
        echo "  sudo chown -R $(whoami):$(whoami) ."
        exit 1
    fi
    
    # Clean up test directory
    rm -rf "$test_dir"
    echo "Directory permissions are correct."
}

# Function to check dependencies
check_dependencies() {
    local missing_deps=()
    
    # Check for required commands
    for cmd in fai-diskimage python3 qemu-utils; do
        if ! command -v "$cmd" &>/dev/null; then
            missing_deps+=("$cmd")
        fi
    done
    
    # If there are missing dependencies, try to install them
    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo "Missing dependencies: ${missing_deps[*]}"
        echo "Attempting to install missing dependencies..."
        
        if [ -f /etc/debian_version ]; then
            # Debian-based system
            if check_root; then
                apt-get update
                apt-get install --no-install-recommends -y \
                    ca-certificates debsums dosfstools fai-server fai-setup-storage \
                    fdisk make python3 python3-libcloud python3-marshmallow python3-pytest \
                    python3-yaml qemu-utils udev
            else
                sudo apt-get update
                sudo apt-get install --no-install-recommends -y \
                    ca-certificates debsums dosfstools fai-server fai-setup-storage \
                    fdisk make python3 python3-libcloud python3-marshmallow python3-pytest \
                    python3-yaml qemu-utils udev
            fi
        elif [ -f /etc/redhat-release ]; then
            # Red Hat-based system
            echo "This script is designed for Debian-based systems."
            echo "For Red Hat-based systems, please install the equivalent packages manually."
            exit 1
        else
            echo "Unsupported system. Please install the required dependencies manually."
            echo "Required: fai-diskimage, python3, qemu-utils, and their dependencies."
            exit 1
        fi
    fi
}

# Main function
main() {
    echo "=== Preparing to build Debian 12 Bookworm Azure VHD Image ==="
    
    # Check and fix permissions
    check_and_fix_permissions
    
    # Check dependencies
    check_dependencies
    
    # Run the actual build script
    echo "=== Running build script ==="
    ./build-azure-vhd.sh "$@"
}

# Make the script executable
chmod +x build-azure-vhd.sh

# Run the main function with all arguments passed to this script
main "$@" 