#!/bin/bash
set -e

# Parse command-line arguments
CLEAN_ALL=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        --clean-all)
            CLEAN_ALL=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--clean-all]"
            echo "  --clean-all: Perform a comprehensive cleanup of all previous build artifacts"
            exit 1
            ;;
    esac
done

# Define output directory structure
BUILD_DIR="./debian-azure-build"
OUTPUT_DIR="$BUILD_DIR/output"
TEMP_DIR="$BUILD_DIR/temp"

# Perform comprehensive cleanup if requested
if [ "$CLEAN_ALL" = true ]; then
    echo "Performing comprehensive cleanup of all previous build artifacts..."
    ./cleanup-all.sh
    echo "Comprehensive cleanup completed."
fi

# Clean up function that will be called on script exit
cleanup_old_files() {
    echo "Cleaning up old build files..."
    
    # Remove any existing build files with the same name pattern
    find . -maxdepth 1 -name "debian-12-bookworm-azure-amd64.*" -type f -delete
    
    # Clean up build directories while preserving final output
    if [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
    fi
    
    echo "Cleanup completed."
}

# Set up exit trap to clean up if the script is interrupted
trap 'echo "Script interrupted. Cleaning up..."; cleanup_old_files' INT TERM

# Function to ensure parent directory exists for a file
ensure_dir_exists() {
    local file_path="$1"
    local dir_path=$(dirname "$file_path")
    
    if [ ! -d "$dir_path" ]; then
        mkdir -p "$dir_path"
    fi
}

# Create directory structure
prepare_directories() {
    echo "Preparing build directories..."
    
    # Clean up any old builds first
    cleanup_old_files
    
    # Create fresh directories
    mkdir -p "$OUTPUT_DIR"
    mkdir -p "$TEMP_DIR"
    
    # Create all necessary directories
    # Config and script directories
    mkdir -p config_space/bookworm/files/etc/cloud/cloud.cfg.d
    mkdir -p config_space/bookworm/files/etc/udev/rules.d
    mkdir -p config_space/bookworm/files/etc/network/cloud-ifupdown-helper
    mkdir -p config_space/bookworm/files/etc/network/cloud-interfaces-template
    mkdir -p config_space/bookworm/files/etc/network/interfaces
    mkdir -p config_space/bookworm/files/etc/network/interfaces.d
    mkdir -p config_space/bookworm/files/etc/dhcp
    mkdir -p config_space/bookworm/files/etc/netplan
    mkdir -p config_space/bookworm/files/etc/systemd/network
    mkdir -p config_space/bookworm/scripts/AZURE
    mkdir -p config_space/bookworm/scripts/AZURE/file-modes

    # Create all specific file parent directories
    ensure_dir_exists "config_space/bookworm/files/etc/cloud/cloud.cfg.d/99-disable-network-config.cfg/AZURE"
    ensure_dir_exists "config_space/bookworm/files/etc/dhcp/dhclient.conf/AZURE"
    ensure_dir_exists "config_space/bookworm/files/etc/network/interfaces.d/eth0/AZURE"
    ensure_dir_exists "config_space/bookworm/files/etc/netplan/01-netcfg.yaml/AZURE"
    ensure_dir_exists "config_space/bookworm/files/etc/systemd/network/10-eth0.network/AZURE"
    
    echo "Directory structure prepared."
}

# Install dependencies if not already installed
install_dependencies() {
    echo "Checking and installing dependencies..."
    
    if ! command -v fai-diskimage &> /dev/null; then
        echo "Installing FAI and other required packages..."
        sudo apt-get update
        sudo apt-get install --no-install-recommends -y \
            ca-certificates debsums dosfstools fai-server fai-setup-storage \
            fdisk make python3 python3-libcloud python3-marshmallow python3-pytest \
            python3-yaml qemu-utils udev
    fi
    
    echo "Dependencies installed."
}

# Enhance network configuration
enhance_network_config() {
    echo "Enhancing network configuration..."
    
    # Create dhclient configuration to ensure DHCP works properly
    ensure_dir_exists "config_space/bookworm/files/etc/dhcp/dhclient.conf/AZURE"
    cat > config_space/bookworm/files/etc/dhcp/dhclient.conf/AZURE << EOF
# Configuration file for /sbin/dhclient.
option rfc3442-classless-static-routes code 121 = array of unsigned integer 8;

send host-name = gethostname();
request subnet-mask, broadcast-address, time-offset, routers,
        domain-name, domain-name-servers, domain-search, host-name,
        dhcp6.name-servers, dhcp6.domain-search, dhcp6.fqdn, dhcp6.sntp-servers,
        netbios-name-servers, netbios-scope, interface-mtu,
        rfc3442-classless-static-routes, ntp-servers;

# Ensure DHCP keeps trying to get an address
retry 300;
timeout 300;
EOF

    # Create a network interfaces.d conf for eth0
    ensure_dir_exists "config_space/bookworm/files/etc/network/interfaces.d/eth0/AZURE"
    cat > config_space/bookworm/files/etc/network/interfaces.d/eth0/AZURE << EOF
auto eth0
allow-hotplug eth0
iface eth0 inet dhcp
EOF

    # Create a basic netplan configuration
    ensure_dir_exists "config_space/bookworm/files/etc/netplan/01-netcfg.yaml/AZURE"
    cat > config_space/bookworm/files/etc/netplan/01-netcfg.yaml/AZURE << EOF
# This file is generated by the debian-cloud-images build process
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: true
      dhcp6: true
      optional: true
EOF

    # Create a systemd-networkd configuration for eth0
    ensure_dir_exists "config_space/bookworm/files/etc/systemd/network/10-eth0.network/AZURE"
    cat > config_space/bookworm/files/etc/systemd/network/10-eth0.network/AZURE << EOF
[Match]
Name=eth0

[Network]
DHCP=yes
IPv6AcceptRA=yes

[DHCP]
UseDNS=yes
UseNTP=yes
UseDomains=yes
UseHostname=yes
RouteMetric=100
EOF

    # Create a script to ensure network is enabled at boot
    ensure_dir_exists "config_space/bookworm/scripts/AZURE/10-enable-networking"
    cat > config_space/bookworm/scripts/AZURE/10-enable-networking << EOF
#!/bin/bash
# Enable networking at boot
echo "Ensuring networking is enabled at boot..."
# Enable systemd networking service
if [ -f \$target/etc/systemd/system/multi-user.target.wants/networking.service ]; then
    echo "Networking service already enabled"
else
    ln -sf /lib/systemd/system/networking.service \$target/etc/systemd/system/multi-user.target.wants/networking.service
fi

# Modify GRUB to ensure network modules are loaded early
if ! grep -q "GRUB_CMDLINE_LINUX.*net.ifnames=0" \$target/etc/default/grub; then
    sed -i 's/GRUB_CMDLINE_LINUX="/GRUB_CMDLINE_LINUX="net.ifnames=0 biosdevname=0 /' \$target/etc/default/grub
fi

# Disable predictable network interface names
if [ ! -e \$target/etc/systemd/network/99-default.link ]; then
    mkdir -p \$target/etc/systemd/network/
    cat > \$target/etc/systemd/network/99-default.link << END
[Link]
NamePolicy=kernel database onboard slot path
MACAddressPolicy=persistent
END
fi
EOF

    # Make the script executable
    chmod +x config_space/bookworm/scripts/AZURE/10-enable-networking
    ensure_dir_exists "config_space/bookworm/scripts/AZURE/file-modes/10-enable-networking"
    echo "0755" > config_space/bookworm/scripts/AZURE/file-modes/10-enable-networking
    
    # Create udev rule for Azure network interfaces
    ensure_dir_exists "config_space/bookworm/files/etc/udev/rules.d/75-cloud-ifupdown.rules/AZURE"
    cat > config_space/bookworm/files/etc/udev/rules.d/75-cloud-ifupdown.rules/AZURE << EOF
# Handle allow-hotplug interfaces
SUBSYSTEM=="net", ACTION=="add", DRIVERS=="hv_netvsc", RUN+="/etc/network/cloud-ifupdown-helper"
EOF

    # Create cloud-init network config disable file
    ensure_dir_exists "config_space/bookworm/files/etc/cloud/cloud.cfg.d/99-disable-network-config.cfg/AZURE"
    cat > config_space/bookworm/files/etc/cloud/cloud.cfg.d/99-disable-network-config.cfg/AZURE << EOF
network: {config: disabled}
EOF
    
    echo "Network configuration enhanced."
}

# Build Debian Bookworm Azure image
build_azure_image() {
    echo "Building Debian 12 Bookworm Azure image..."
    
    # Modify the Makefile to use our directory structure
    cat > Makefile.bookworm-azure << EOF
# Build Debian 12 Bookworm Azure image in VHD format
DESTDIR = $TEMP_DIR
OUTPUT_DIR = $OUTPUT_DIR

all: vhd

# First, build the raw image
raw:
	umask 022; \\
	./bin/debian-cloud-images build \\
	  bookworm azure amd64 \\
	  --build-id manual \\
	  --version \$(shell date '+%Y%m%d%H%M') \\
	  --localdebs \\
	  --output \$(DESTDIR) \\
	  --override-name debian-12-bookworm-azure-amd64

# Convert the raw image to VHD format
vhd: raw
	python3 convert_to_vhd.py --input-dir \$(DESTDIR) --output-dir \$(OUTPUT_DIR) --overwrite

clean:
	rm -rf \$(DESTDIR)/debian-12-bookworm-azure-amd64.*

.PHONY: all raw vhd clean
EOF
    
    # Run the build
    make -f Makefile.bookworm-azure
    
    # Copy important files to output directory for convenience
    cp $TEMP_DIR/*.info $OUTPUT_DIR/ 2>/dev/null || true
    cp $TEMP_DIR/*.build.json $OUTPUT_DIR/ 2>/dev/null || true
    
    echo "Build completed successfully."
}

# Main execution
main() {
    echo "=== Starting Debian 12 Bookworm Azure VHD Image Build ==="
    
    install_dependencies
    prepare_directories
    enhance_network_config
    build_azure_image
    
    echo "=== Build Process Complete ==="
    echo "VHD image is available at: $OUTPUT_DIR/debian-12-bookworm-azure-amd64.vhd"
    echo "All build artifacts are stored in: $BUILD_DIR"
}

# Run the main function
main

# Display final message
echo ""
echo "To clean up all build files except the final output, run: rm -rf $TEMP_DIR"
echo "To use a fresh build environment next time, run: rm -rf $BUILD_DIR"
echo "For a complete cleanup of all artifacts, run: ./cleanup-all.sh"
echo "You can also run this script with --clean-all to perform cleanup before building." 