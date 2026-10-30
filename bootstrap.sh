#!/bin/bash
# bootstrap.sh - One-line installer for macbook-thermal-control
# Downloads the repo via zip (no git required) and runs the installer.
# Usage: curl -fsSL https://raw.githubusercontent.com/hugofer93/macbook-thermal-control/main/bootstrap.sh | bash

set -e

# Check architecture - not supported on Apple Silicon
ARCH=$(uname -m)
if [[ "$ARCH" == "arm64" ]]; then
    echo "❌ Error: This tool is designed for Intel Macs (2016-2020) only"
    echo "   Apple Silicon Macs (ARM) don't need this thermal control"
    echo "   They manage thermals efficiently without external tools"
    exit 1
fi

REPO="https://github.com/hugofer93/macbook-thermal-control"
INSTALL_DIR="${HOME}/.local/share/macbook-thermal-control"
ZIP_URL="${REPO}/archive/refs/heads/main.zip"
TMP_ZIP=$(mktemp -t mbmc-XXXXXX.zip)

echo "📥 Downloading macbook-thermal-control..."

# Download the latest release as zip
curl -fsSL -o "${TMP_ZIP}" "${REPO}/archive/refs/heads/main.zip"

# Extract to a temporary directory
TMP_DIR=$(mktemp -d -t mbmc-XXXXXX)
unzip -q "${TMP_ZIP}" -d "${TMP_DIR}"

# Find the extracted folder (GitHub zips create a folder like repo-main/)
EXTRACTED_DIR=$(find "${TMP_DIR}" -maxdepth 1 -type d -name "macbook-thermal-control*" | head -1)

if [[ -z "${EXTRACTED_DIR}" ]]; then
    echo "❌ Error: Failed to find extracted directory"
    exit 1
fi

# Remove existing installation if present
rm -rf "${INSTALL_DIR}"

# Move extracted repo to install directory
mv "${EXTRACTED_DIR}" "${INSTALL_DIR}"

# Cleanup
rm -f "${TMP_ZIP}"
rm -rf "${TMP_DIR}"

echo "🔧 Running installer..."
exec "${INSTALL_DIR}/install.sh"
