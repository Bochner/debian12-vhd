# Debian 12 Bookworm Azure VHD Image Builder

This repository is a simplified version of the debian-cloud-images project, focused exclusively on building Debian 12 Bookworm images for Microsoft Azure in VHD format with working network connectivity.

## Prerequisites

- A Debian-based system
- The following packages (will be installed by the build script if missing):
  - fai-server
  - fai-setup-storage
  - python3
  - qemu-utils
  - and other dependencies

## Quick Start

Simply run the build script:

```bash
./build-azure-vhd.sh
```

This will:
1. Clean up any old build files
2. Install necessary dependencies
3. Create a properly organized build environment
4. Create enhanced network configuration for Azure
5. Build a Debian 12 Bookworm image in RAW format
6. Convert it to VHD format suitable for Azure and Hyper-V

The resulting VHD file will be in the `debian-azure-build/output` directory, named `debian-12-bookworm-azure-amd64.vhd`.

## Cleanup Options

If you need to clean up all artifacts from previous runs, you have two options:

1. Run the dedicated cleanup script:
   ```bash
   ./cleanup-all.sh
   ```
   This will remove all build artifacts, output files, and configuration directories.

2. Run the build script with the clean-all flag:
   ```bash
   ./build-azure-vhd.sh --clean-all
   ```
   This will perform a comprehensive cleanup before starting the build process.

## Improved Organization

This version uses a dedicated folder structure:
- `debian-azure-build/` - Main build directory
  - `output/` - Contains the final VHD image and metadata files
  - `temp/` - Contains temporary build files that are cleaned up

## Enhanced Network Configuration

This version addresses network connectivity issues in the standard Debian 12 Bookworm Azure images by:

1. Disabling cloud-init network configuration, allowing the Azure agent to manage it correctly
2. Adding proper udev rules for Azure network interfaces
3. Setting up proper network interface templates for DHCP
4. Configuring a systemd-networkd profile to ensure interfaces come up properly
5. Modifying the DHCP client configuration for better reliability
6. Ensuring proper boot-time network module loading
7. Disabling predictable network interface names for better Hyper-V compatibility

## Manual Process

If you want to run the steps manually:

1. First, set up the environment:
   ```bash
   BUILD_DIR="./debian-azure-build"
   OUTPUT_DIR="$BUILD_DIR/output"
   TEMP_DIR="$BUILD_DIR/temp"
   mkdir -p $OUTPUT_DIR $TEMP_DIR
   ```

2. Build the raw image:
   ```bash
   make -f Makefile.bookworm-azure raw
   ```

3. Convert the raw image to VHD format:
   ```bash
   make -f Makefile.bookworm-azure vhd
   ```

## Using the VHD Image

The resulting VHD image can be uploaded to Azure or used directly with Hyper-V. The image has:

- Guaranteed network connectivity with DHCP support
- Azure Linux Agent (waagent) pre-installed
- Cloud-init for system initialization
- HyperV daemons for better integration with the hypervisor

## Cleaning Up

The build script automatically cleans up old files before starting a new build.

To clean up manually:
```bash
# Remove temporary build files while keeping the final output
rm -rf ./debian-azure-build/temp

# Remove everything including the final output
rm -rf ./debian-azure-build

# For a comprehensive cleanup of all artifacts
./cleanup-all.sh
``` 