# Portable Debian 12 Azure VHD Builder

This guide explains how to build a Debian 12 (Bookworm) Azure VHD image on any system without permission issues.

## Prerequisites

- A Debian-based Linux system (Ubuntu, Debian, etc.)
- Internet connection to download packages
- Basic command-line knowledge

## Quick Start

To build the Debian 12 Azure VHD image, simply run:

```bash
./run-build.sh
```

This wrapper script will:
1. Check and fix permissions automatically
2. Install any missing dependencies
3. Run the actual build script

## Permissions

The wrapper script automatically handles permission issues by:
- Checking if the current user has write access to the necessary directories
- Fixing permissions using sudo if needed
- Verifying that directories can be created successfully

## Options

You can pass any options to the wrapper script, and they will be forwarded to the build script:

```bash
./run-build.sh --clean-all
```

## Troubleshooting

If you encounter any issues:

1. **Permission Denied**: The script will attempt to fix permissions automatically. If it fails, you may need to run:
   ```bash
   sudo chown -R $(whoami):$(whoami) .
   ```

2. **Missing Dependencies**: The script will attempt to install dependencies automatically. If it fails, you may need to install them manually:
   ```bash
   sudo apt-get install ca-certificates debsums dosfstools fai-server fai-setup-storage fdisk make python3 python3-libcloud python3-marshmallow python3-pytest python3-yaml qemu-utils udev
   ```

3. **Non-Debian Systems**: The script is designed for Debian-based systems. For other systems, you'll need to install equivalent packages manually.

## Git Issues with Symlinks

If you're using Git with this project, you may encounter issues with symlinks, especially on Windows Subsystem for Linux (WSL). The repository includes a `.gitignore` file that excludes problematic symlinks.

If you encounter Git errors about symlinks:

1. Remove the symlink from Git's index:
   ```bash
   git rm --cached path/to/problematic/symlink
   ```

2. Add the path to `.gitignore`:
   ```bash
   echo "path/to/problematic/symlink" >> .gitignore
   ```

3. Commit the changes:
   ```bash
   git add .gitignore
   git commit -m "Exclude problematic symlink"
   ``` 