#!/bin/bash
# Comprehensive cleanup script to remove all artifacts from previous builds

echo "=== Starting comprehensive cleanup of all build artifacts ==="

# Define directories to clean
BUILD_DIR="./debian-azure-build"
CONFIG_DIRS=(
  "config_space/bookworm/files/etc/cloud/cloud.cfg.d/99-disable-network-config.cfg"
  "config_space/bookworm/files/etc/udev/rules.d"
  "config_space/bookworm/files/etc/network/cloud-ifupdown-helper"
  "config_space/bookworm/files/etc/network/cloud-interfaces-template"
  "config_space/bookworm/files/etc/network/interfaces"
  "config_space/bookworm/files/etc/dhcp/dhclient.conf"
  "config_space/bookworm/files/etc/network/interfaces.d/eth0"
  "config_space/bookworm/files/etc/netplan/01-netcfg.yaml"
  "config_space/bookworm/files/etc/systemd/network/10-eth0.network"
  "config_space/bookworm/scripts/AZURE"
)

# 1. Remove the main build directory
if [ -d "$BUILD_DIR" ]; then
  echo "Removing build directory: $BUILD_DIR"
  rm -rf "$BUILD_DIR"
fi

# 2. Remove all files matching the output pattern in current directory
echo "Removing any stray output files in current directory"
find . -maxdepth 1 -name "debian-12-bookworm-azure-amd64.*" -type f -delete

# 3. Remove all configuration directories created for the build
echo "Removing configuration directories"
for dir in "${CONFIG_DIRS[@]}"; do
  if [ -d "$dir" ]; then
    echo "  - Removing: $dir"
    rm -rf "$dir"
  fi
done

# 4. Remove generated Makefile
if [ -f "Makefile.bookworm-azure" ]; then
  echo "Removing generated Makefile"
  rm -f Makefile.bookworm-azure
fi

# 5. Clean up any temporary files that might have been created
echo "Cleaning up temporary files"
find . -name "*.tmp" -type f -delete
find . -name "*.bak" -type f -delete

# 6. Check for and clean up config_space/build directory
if [ -d "config_space/build" ]; then
  echo "Removing build artifacts in config_space/build"
  rm -rf config_space/build
fi

echo "=== Cleanup complete ==="
echo "You can now run ./build-azure-vhd.sh to start a fresh build" 