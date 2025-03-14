#!/bin/bash
# Script to verify the VHD image for Azure/Hyper-V

BUILD_DIR="./debian-azure-build"
OUTPUT_DIR="$BUILD_DIR/output"

if [ ! -d "$OUTPUT_DIR" ]; then
    echo "Error: Output directory $OUTPUT_DIR not found."
    echo "Please run build-azure-vhd.sh first to generate the image."
    exit 1
fi

VHD_FILE=$(find "$OUTPUT_DIR" -name "*.vhd" | head -n 1)

if [ -z "$VHD_FILE" ]; then
    echo "Error: No VHD file found in $OUTPUT_DIR."
    echo "Please run build-azure-vhd.sh first to generate the image."
    exit 1
fi

echo "================================================"
echo "Verification of VHD Image for Azure/Hyper-V"
echo "================================================"
echo "Image file: $VHD_FILE"
echo ""

# Get file size and format
SIZE=$(du -h "$VHD_FILE" | cut -f1)
echo "Image size: $SIZE"

# Verify VHD format
echo ""
echo "Checking VHD format..."
qemu-img info "$VHD_FILE"

# List all files in the output directory
echo ""
echo "Output directory contents:"
ls -lh "$OUTPUT_DIR"

echo ""
echo "Verification complete."
echo "Your VHD image appears to be ready for Azure/Hyper-V."
echo ""
echo "Next steps:"
echo "1. Upload the VHD to Azure storage or import into Hyper-V"
echo "2. Create a VM from the VHD"
echo "3. Verify network connectivity when the VM starts"
echo "" 