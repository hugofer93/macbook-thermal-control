#!/bin/bash
# macbook-thermal-control - Uninstaller

set -e

echo "=========================================="
echo "  macbook-thermal-control - Uninstaller"
echo "=========================================="
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLIST_DEST="/Library/LaunchDaemons/com.user.macbook-thermal-control.plist"
WRAPPER_PATH="/usr/local/bin/macbook-thermal-control"

echo "This will remove:"
echo "  - $SCRIPT_DIR"
echo "  - LaunchDaemon service (if installed)"
echo "  - Wrapper script at /usr/local/bin/macbook-thermal-control"
echo ""
read -p "Continue? (y/N) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 1
fi

# Stop and unload launchd service (requires sudo)
if [[ -f "$PLIST_DEST" ]]; then
    echo "🔧 Stopping launchd service (requires sudo)..."
    sudo launchctl unload "$PLIST_DEST" 2>/dev/null || true
    sudo rm -f "$PLIST_DEST"
    echo "✅ LaunchDaemon removed"
fi

# Kill any running instances (may need sudo since service runs as root)
sudo pkill -f "macbook-max-cooling.py" 2>/dev/null || true
sudo pkill -f "macbook-thermal-control" 2>/dev/null || true

# Remove wrapper script
if [[ -f "/usr/local/bin/macbook-thermal-control" ]]; then
    echo "🗑️  Removing wrapper script..."
    sudo rm -f /usr/local/bin/macbook-thermal-control
    echo "✅ Wrapper script removed"
fi

# Remove the directory
cd ..
rm -rf "$SCRIPT_DIR"

echo ""
echo "✅ Uninstall complete!"
echo ""
echo "Note: cpulimit was not removed (may be used by other tools)"
echo "To remove it: brew uninstall cpulimit"
echo "Note: Macs Fan Control was not removed (may be used by other tools)"
echo "To remove it: brew uninstall --cask macs-fan-control"
