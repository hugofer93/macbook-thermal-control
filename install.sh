#!/bin/bash
# macbook-thermal-control - Installer

set -e

echo "=========================================="
echo "  macbook-thermal-control - Installer"
echo "=========================================="
echo ""

# Check macOS
if [[ "$(uname)" != "Darwin" ]]; then
    echo "❌ This script only runs on macOS"
    exit 1
fi

# Check architecture
ARCH=$(uname -m)
if [[ "$ARCH" == "arm64" ]]; then
    echo "❌ Error: This tool is designed for Intel Macs (2015-2020) only"
    echo "   Apple Silicon Macs (ARM) don't need this thermal control"
    echo "   They manage thermals efficiently without external tools"
    exit 1
fi

# Check Homebrew
if ! command -v brew &> /dev/null; then
    echo "❌ Homebrew not found. Install from https://brew.sh"
    exit 1
fi

# Install cpulimit (runs as current user, not root)
echo "📦 Installing cpulimit..."
if brew list cpulimit &> /dev/null; then
    echo "✅ cpulimit already installed"
else
    brew install cpulimit
fi

# Install Macs Fan Control (optional but recommended)
echo "📦 Installing Macs Fan Control (optional but recommended)..."
if brew list --cask macs-fan-control &> /dev/null; then
    echo "✅ Macs Fan Control already installed"
else
    read -p "Install Macs Fan Control? (Y/n) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        brew install --cask macs-fan-control
    else
        echo "⏭️  Skipping Macs Fan Control"
    fi
fi

# Check Python 3
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 not found"
    echo "   Install it with: brew install python3"
    exit 1
fi

# Detect installation directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_PATH="$SCRIPT_DIR/scripts/macbook-max-cooling.py"
WRAPPER_PATH="/usr/local/bin/macbook-thermal-control"
WRAPPER_SOURCE="$SCRIPT_DIR/macbook-thermal-control.sh"

# Make script executable
chmod +x "$SCRIPT_PATH"

# Install wrapper script to /usr/local/bin with correct install directory
echo "📦 Installing wrapper script..."
sudo mkdir -p /usr/local/bin
sed "s|__INSTALL_DIR__|$SCRIPT_DIR|g" "$WRAPPER_SOURCE" | sudo tee /usr/local/bin/macbook-thermal-control > /dev/null
sudo chmod +x /usr/local/bin/macbook-thermal-control

# Generate launchd plist with actual wrapper path
PLIST_TEMPLATE="$SCRIPT_DIR/launchd/macbook-thermal-control.plist"
PLIST_DEST="/Library/LaunchDaemons/com.user.macbook-thermal-control.plist"

echo ""
echo "🔧 Setting up launchd service (requires sudo)..."

# Create LaunchDaemons directory if needed
sudo mkdir -p /Library/LaunchDaemons

# Generate plist with actual wrapper path
sed "s|__SCRIPT_PATH__|/usr/local/bin/macbook-thermal-control|g" \
    "$PLIST_TEMPLATE" | sudo tee "$PLIST_DEST" > /dev/null

# Load the service (requires sudo)
echo "🔧 Installing launchd service (requires sudo)..."
sudo launchctl unload "$PLIST_DEST" 2>/dev/null || true
sudo launchctl load "$PLIST_DEST"
echo "✅ Service installed and started. Will run automatically at boot as root."

echo ""
echo "✅ Installation complete!"
echo ""
echo "Usage (manual run):"
echo "  $WRAPPER_PATH"
echo ""
echo "Recommended: Configure Macs Fan Control with fan curve:"
echo "  Fan starts increasing at 35°C"
echo "  Maximum fan speed at 50°C"
echo ""
echo "To uninstall, run: sudo ~/.local/share/macbook-thermal-control/uninstall.sh"
