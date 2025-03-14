#!/usr/bin/env python3
"""
Convert raw disk images to VHD format for Azure and Hyper-V compatibility.
This script finds raw disk images in a specified directory and converts them to VHD format.
"""

import os
import subprocess
import argparse
import logging
from pathlib import Path
import shutil

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def check_dependencies():
    """Check if qemu-img is installed."""
    try:
        subprocess.run(['qemu-img', '--version'], 
                      stdout=subprocess.PIPE, 
                      stderr=subprocess.PIPE, 
                      check=True)
        logger.info("qemu-img is available.")
        return True
    except (subprocess.SubprocessError, FileNotFoundError):
        logger.error("qemu-img not found. Please install qemu-utils package.")
        return False

def convert_raw_to_vhd(input_file, output_file):
    """
    Convert a raw disk image to VHD format using qemu-img.
    
    Args:
        input_file (str): Path to the raw disk image
        output_file (str): Path where the VHD file will be created
    
    Returns:
        bool: True if conversion was successful, False otherwise
    """
    try:
        logger.info(f"Converting {input_file} to {output_file}")
        
        # Convert raw to VHD format
        cmd = [
            'qemu-img', 'convert',
            '-f', 'raw',  # Input format
            '-O', 'vpc',  # Output format (vpc = VHD)
            '-o', 'subformat=fixed',  # Fixed size VHD
            input_file, output_file
        ]
        
        subprocess.run(cmd, check=True, stderr=subprocess.PIPE)
        logger.info(f"Successfully converted {input_file} to VHD format")
        return True
    except subprocess.CalledProcessError as e:
        logger.error(f"Conversion failed: {str(e)}")
        logger.error(f"Error output: {e.stderr.decode() if e.stderr else 'None'}")
        return False

def process_directory(input_dir, output_dir, overwrite=False):
    """
    Process all raw disk images in the input directory and convert them to VHD.
    
    Args:
        input_dir (str): Directory containing raw disk images
        output_dir (str): Directory where VHD files will be stored
        overwrite (bool): Whether to overwrite existing VHD files
    """
    input_path = Path(input_dir)
    output_path = Path(output_dir)
    
    # Create output directory if it doesn't exist
    output_path.mkdir(parents=True, exist_ok=True)
    
    count = 0
    # Find all .raw files in input directory
    for raw_file in input_path.glob('*.raw'):
        vhd_filename = raw_file.stem + '.vhd'
        vhd_filepath = output_path / vhd_filename
        
        # Check if output file already exists
        if vhd_filepath.exists() and not overwrite:
            logger.warning(f"Output file {vhd_filepath} already exists. Skipping. Use --overwrite to force conversion.")
            continue
            
        # Perform the conversion
        success = convert_raw_to_vhd(str(raw_file), str(vhd_filepath))
        if success:
            count += 1
    
    logger.info(f"Conversion complete. {count} file(s) converted.")

def main():
    """Main entry point for the script."""
    parser = argparse.ArgumentParser(description='Convert raw disk images to VHD format for Azure and Hyper-V compatibility.')
    parser.add_argument('--input-dir', default='debian12_azure', 
                        help='Directory containing raw disk images (default: debian12_azure)')
    parser.add_argument('--output-dir', default='vhd_output', 
                        help='Directory where VHD files will be stored (default: vhd_output)')
    parser.add_argument('--overwrite', action='store_true', 
                        help='Overwrite existing VHD files')
    
    args = parser.parse_args()
    
    if not check_dependencies():
        return 1
    
    process_directory(args.input_dir, args.output_dir, args.overwrite)
    
    return 0

if __name__ == '__main__':
    exit(main()) 